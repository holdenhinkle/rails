# frozen_string_literal: true

module ActionView # :nodoc:
  # = Action View PathSet
  #
  # This class is used to store and access paths in Action View. A number of
  # operations are defined so that you can search among the paths in this
  # set and also perform operations on other +PathSet+ objects.
  #
  # A +LookupContext+ will use a +PathSet+ to store the paths in its context.
  class PathSet # :nodoc:
    include Enumerable

    attr_reader :paths

    delegate :[], :include?, :size, :each, to: :paths

    def initialize(paths = [])
      @paths = typecast(paths).freeze
    end

    def initialize_copy(other)
      @paths = other.paths.dup.freeze
      self
    end

    def to_ary
      paths.dup
    end

    def compact
      PathSet.new paths.compact
    end

    def +(array)
      PathSet.new(paths + array)
    end

    def find(path, prefixes, partial, details, details_key, locals)
      find_all(path, prefixes, partial, details, details_key, locals).first ||
        raise(MissingTemplate.new(self, path, prefixes, partial, details, details_key, locals))
    end

    def find_all(path, prefixes, partial, details, details_key, locals)
      search_combinations(prefixes) do |resolver, prefix|
        templates = resolver.find_all(path, prefix, partial, details, details_key, locals)
        return templates unless templates.empty?
      end
      []
    end

    def exists?(path, prefixes, partial, details, details_key, locals)
      find_all(path, prefixes, partial, details, details_key, locals).any?
    end

    private
      def search_combinations(prefixes)
        prefixes = Array(prefixes)
        prefixes.each do |prefix|
          paths.each do |resolver|
            yield resolver, prefix
          end
        end
      end

      def typecast(paths)
        paths.map do |path|
          case path
          when Pathname, String
            ViewPaths::Registry.file_system_resolver(path.to_s)
          when Resolver
            path
          else
            raise TypeError, "#{path.inspect} is not a valid path: must be a String, Pathname, or Resolver"
          end
        end
      end
  end
end
