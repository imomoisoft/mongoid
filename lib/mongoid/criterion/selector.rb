# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:

    class Selector < Hash
      attr_reader :klass

      def initialize(klass)
        @klass = klass
      end

      def []=(key, value)
        super(key, try_to_typecast(key, value))
      end

      def merge!(other)
        other.each_pair do |key, value|
          self[key] = value
        end
        self
      end
      alias update merge!

      private

      def try_to_typecast(key, value)
        access = key.to_s
        return value unless klass.fields.has_key?(access)

        field = klass.fields[access]
        typecast_value_for(field, value)
      end

      def typecast_value_for(field, value)
        return value if field.type === value
        case value
        when Hash
          value = value.dup
          value.each_pair do |k, v|
            unless %w($exists $size $elemMatch).include?(k)
              value[k] = typecast_value_for(field, v)
            end
          end
        when Array
          value.map { |v| typecast_value_for(field, v) }
        when Regexp
          value
        else
          field.set(value)
        end
      end

    end

  end
end
