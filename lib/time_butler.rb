require 'mongo'
require 'logger'
require 'set'
require 'singleton'

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
  # @param [ Int ] inc: Amount of days.
  #                     Defaults to: 1
  #
  # @return [ Void ]
  def self.go_ahead(days: 1)
    instance.run(days: days)
  end

  # Increase all age fields by one day.
  #
  # @param [ Int ] inc: Amount of days.
  #                     Defaults to: 1
  #
  # @return [ Void ]
  def self.go_back(days: 1)
    instance.run(days: -days)
  end

  # Increase all age fields by the amount of days.
  #
  # @param [ Int ] inc: Amount of days.
  #                     Defaults to: 1
  #
  # @return [ Void ]
  def run(days: 1)
    inc_hash_feeds(days)
    inc_array_feeds(days)
  end

  # List of all root keys which link to a sub-document of the specified class.
  #
  # @param [ Class ] type The class to search for.
  #
  # @return [ Set<String> ]
  def feed_names_of_type(type)
    db[:stocks].find.limit(50).each_with_object(Set.new) do |rec, names|
      rec.each_pair { |k, v| names << k if v.is_a? type }
    end.to_a
  end

  private

  # Increase all age fields by the specified amount of days. The method only
  # updates sub-documents that are a hash.
  #
  # @param [ Int ] days Amount of days.
  #
  # @return [ Void ]
  def inc_hash_feeds(days)
    feeds = feed_names_of_type(Hash)
    ages  = {}

    feeds.each { |name| ages["#{name}.meta.age"] = days }

    outdated_stocks.update_many('$inc': ages)
  end

  # Increase all age fields by the specified amount of days. The method only
  # updates sub-documents that are an array.
  #
  # @param [ Int ] days Amount of days.
  #
  # @return [ Void ]
  def inc_array_feeds(days)
    feeds  = feed_names_of_type(Array)
    stocks = outdated_stocks.batch_size(500)
                            .projection(to_h(feeds, true).merge!(_id: true))

    stocks.each_slice(500).each do |bunch|
      opts = bulk_inc_age_instructions(bunch, feeds, days)
      db[:stocks].bulk_write(opts, ordered: false)
    end
  end

  # For each stock get the instructions to increase the age property of all
  # array items and put them into one update instruction per stock.
  # Finally all update instructions for all stocks as an array so it can be
  # used for a bulk write operation.
  #
  # @example
  #   bulk_inc_age_instructions stocks, [:history], 1
  #   # => [{ update_one: { filter:, update: { $inc: { history.0.age: 1 } } } }]
  #
  # @param [ Array<Hash> ] stocks List of stock objects.
  # @param [ Array<String> ] feed_names Property names that hold an array.
  # @param [ Int ] days Amount of days to increase.
  #
  # @return [ Hash ]
  def bulk_inc_age_instructions(stocks, feed_names, days)
    stocks.each_with_object([]) do |rec, bulk|
      ages = inc_age_instructions(rec, feed_names, days)

      next if ages.empty?

      bulk << { update_one: { filter: { _id: rec[:_id] },
                              update: { '$inc': ages } } }
    end
  end

  # Convert all items of the provided feed names of the stock into a $inc
  # instruction that can be used later for bulk write operations.
  #
  # @example
  #   inc_age_instructions stock, [:history], 1
  #   # => { 'history.1.age': 1, 'history.2.age': 1 }
  #
  # @param [ Hash ] stock A mongo bson document.
  # @param [ Array<String> ] feed_names Property names that hold an array.
  # @param [ Int ] days Amount of days to increase.
  #
  # @return [ Hash ]
  def inc_age_instructions(stock, feed_names, days)
    feed_names.map do |feed|
      case feed
      when 'events'
        to_h to_a(stock[:events], :events, :occurs_in), -days
      else
        to_h to_a(stock[feed], feed, :age), days
      end
    end.reduce :merge!
  end

  # Convert an array to a form that fits to what $inc expects.
  #
  # @example
  #   to_a [item0, item1], 'history', 'age'
  #   # => ['history.0.age', 'history.1.age']
  #
  # @param [ Array ] ary
  # @param [ String ] pref The prefix infront of the index.
  # @param [ String ] suf The suffix behind the index.
  #
  # @return [ Array<String> ]
  def to_a(ary, pref, suf = 'age')
    return [] if !ary || ary.empty?
    ary.each_index.map { |i| "#{pref}.#{i}.#{suf}" }
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
