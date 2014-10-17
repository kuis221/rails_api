module Sunspot
  module TrendObjectAdapter
    def self.included(base)
      base.class_eval do
        extend Sunspot::Rails::Searchable::ActsAsMethods
        Sunspot::Adapters::DataAccessor.register(DataAccessor, base)
        Sunspot::Adapters::InstanceAdapter.register(InstanceAdapter, base)

        def self.before_save(*args); end

        def self.after_save(*args);  end

        def self.after_destroy(*args); end
      end
    end

    class InstanceAdapter < Sunspot::Adapters::InstanceAdapter
      def id
        @instance.id
      end
    end

    class DataAccessor < Sunspot::Adapters::DataAccessor
      def load(id)
        find_by_ids([id]).first
      end

      def load_all(ids)
        find_by_ids(ids)
      end

      private

      def find_by_ids(ids)
        @clazz.load_objects(ids)
      end
    end
  end
end