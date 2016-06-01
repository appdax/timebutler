# rubocop:disable all
#
# Extracted source code from the `key_path` gem.
# See https://github.com/nickcharlton/keypath-ruby/blob/master/lib/key_path/hash/extensions.rb

module KeyPath
  # A Mixin for Hash which allows us to create a path from a key.
  module HashExtensions
    # Find all paths in the collection that end with the specified key.
    #
    # @example Find paths in a nested hash.
    #   { meta: { age: 1 } }.keypaths_for_nested_key :age
    #   # => 'meta.age': 1
    #
    # example Find paths in a nested array.
    #   { events: [{ occurs_in: 1 }] }.keypaths_for_nested_key :occurs_in
    #   # => 'events.0.occurs_in': 1
    #
    # @param [ String ] nested_key The key to search for.
    #
    # @return [ Hash ] Mathing paths and their values.
    def keypaths_for_nested_key(nested_key = '', nested_hash = self,
                                path = [], all_values = [])
      nested_hash.each do |k, v|
        path << k.to_s # assemble the path from the key
        case v
        when Array then
          v.each_with_index do |item, i|
            next unless item.kind_of? Enumerable
            path << "#{i}" # add the array key
            keypaths_for_nested_key(nested_key, item, path, all_values)
          end
          path.pop # remove the array key
        when Hash then keypaths_for_nested_key(nested_key, v, path, all_values)
        else
          all_values << path.join('.') if k == nested_key

          path.pop
        end
      end
      path.pop

      all_values
    end
  end
end

# Mix `HashExtensions` into `Hash`.
class Hash
  include KeyPath::HashExtensions
end

# rubocop:enable all
