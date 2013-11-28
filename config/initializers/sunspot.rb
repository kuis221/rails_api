# We are not using delayed reindexing to reduce the delay on listings. For example, activating/deactivating items on the list


# To reindex using delayed job
# unless defined?($rails_rake_task) && $rails_rake_task && !Rake.application.top_level_tasks.include?('jobs:work')
#   require "sunspot/queue/delayed_job"
#   backend = Sunspot::Queue::DelayedJob::Backend.new
#   Sunspot.session = Sunspot::Queue::SessionProxy.new(Sunspot.session, backend)
# end


# To reindex using resque
unless Rails.env.test? || defined?(Rails::Console) || (defined?($rails_rake_task) && $rails_rake_task && !Rake.application.top_level_tasks.include?('resque:work'))
  require "sunspot/queue/resque"
  backend = Sunspot::Queue::Resque::Backend.new
  Sunspot.session = Sunspot::Queue::SessionProxy.new(Sunspot.session, backend)
end


module Sunspot #:nodoc:
  module Rails #:nodoc:
    #
    # This module provides Sunspot Adapter implementations for ActiveRecord
    # models.
    #
    module Adapters
      class EventDataAccessor < Sunspot::Rails::Adapters::ActiveRecordDataAccessor
        private

        def options_for_find
          options = super.merge(joins: joins_for_find.keys.map{|r| "LEFT JOIN #{r.to_s.pluralize} ON #{r.to_s.pluralize}.id = events.#{r.to_s}_id"})
          options[:select] = [options[:select] || 'events.*', joins_for_find.map{|k, v| v.map{|field| "#{k.to_s.pluralize}.#{field} as #{k.to_s}_#{field}" } }.flatten.join(', ')].compact.join(',')
          options
        end

        def joins_for_find
          {
            campaign: [:name],
            place: [:name, :city, :state, :country, :zipcode, :street_number, :route, :formatted_address]
          }
        end
      end
    end
  end
end

Sunspot::Adapters::DataAccessor.register(Sunspot::Rails::Adapters::EventDataAccessor, Event)