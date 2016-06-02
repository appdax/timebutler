require 'mongo'
require 'logger'
require 'set'
require 'singleton'
require 'extensions/key_path'

# The TimeButler class provides an easy way to increase or decrease all `age`
# properties within a stock and its sub documents.
# He does only modify stock objects that haven't been updated at the same day,
# e.g. only older ones.
#
# @example Increase the timestamps by one day.
#   Stocks.first.intraday.age => 1
#   TimeButler.go_ahead
#   Stocks.first.intraday.age => 2
#
# @example Decrease the timestamps by two day.
#   Stocks.first.intraday.age => 10
#   TimeButler.go_back days: 2
#   Stocks.first.intraday.age => 8
class TimeButler
  include Singleton

  # Increase all age fields by one day.
  #
  # @param [ Int ] days Amount of days.
  #                     Defaults to: 1
  #
  # @return [ Void ]
  def self.go_ahead(days = 1)
    instance.run(days: days)
  end

  # Increase all age fields by one day.
  #
  # @param [ Int ] days Amount of days.
  #                     Defaults to: 1
  #
  # @return [ Void ]
  def self.go_back(days = 1)
    instance.run(days: -days)
  end

  # Increase all age fields by the amount of days.
  #
  # @param [ Int ] inc: Amount of days.
  #                     Defaults to: 1
  #
  # @return [ Void ]
  def run(days: 1)
    stocks = outdated_stocks.batch_size(500)

    stocks.each_slice(500).each do |bunch|
      opts = update_instructions_for_stocks(bunch, days)

      db[:stocks].bulk_write(opts, ordered: false)
    end
  end

  private

  # For each stock get the instructions to increase any age property  and put
  # them into one update instruction per stock. Finally all update instructions
  # for all stocks as an array so it can be used for a bulk write operation.
  #
  # @example
  #   bulk_inc_age_instructions stocks, [:history], 1
  #   # => [{ update_one: { filter:, update: { $inc: { history.0.age: 1 } } } }]
  #
  # @param [ Array<Hash> ] stocks List of stock objects.
  # @param [ Int ] days Amount of days to increase.
  #
  # @return [ Hash ]
  def update_instructions_for_stocks(stocks, days)
    stocks.each_with_object([]) do |rec, bulk|
      ages = update_instructions_for_stock(rec, days)

      next if ages.empty?

      bulk << { update_one: { filter: { _id: rec[:_id] },
                              update: { '$inc': ages } } }
    end
  end

  # Convert all paths that contain age informations into a $inc instruction
  # that can be used later for bulk write operations.
  #
  # @example
  #   inc_age_instructions stock, 1
  #   # => { 'history.0.age': 1, 'intraday.meta.age': 1 }
  #
  # @param [ Hash ] stock A mongo bson document.
  # @param [ Int ] days Amount of days to increase.
  #
  # @return [ Hash ]
  def update_instructions_for_stock(stock, days)
    [
      to_h(stock.keypaths_for_nested_key('age'), days),
      to_h(stock.keypaths_for_nested_key('occurs_in'), -days)
    ].reduce :merge!
  end

  # Convert an Array to a Hash where the items of the array map to the keys of
  # the hash and each value maps to the specified value.
  #
  # @example
  #   to_h ['k1', 'k2'], 'v'
  #   # => { k1: 'v', 'k2': 'v' }
  #
  # @param [ Array ] ary Any array instance.
  # @param [ Object ] val Any object.
  #
  # @return [ Hash ]
  def to_h(ary, val)
    return {} if ary.empty?
    Hash[*ary.product([val]).flatten!]
  end

  # Scoped stocks collection to search for only stocks older than today.
  #
  # @return [ Mongo::View ]
  def outdated_stocks
    db[:stocks].find updated_at: { '$lt': Time.now.utc }
  end

  # Client instance to connect to the Mongo DB.
  #
  # @return [ Mongo::Client ]
  def db
    @connection ||= begin
      Mongo::Logger.logger.level = Logger::WARN
      Mongo::Client.new ENV['MONGO_URI']
    end
  end
end
