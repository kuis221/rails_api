# We are not using delayed reindexing to reduce the delay on listings. For example, activating/deactivating items on the list


# To reindex using delayed job
# unless defined?($rails_rake_task) && $rails_rake_task && !Rake.application.top_level_tasks.include?('jobs:work')
#   require "sunspot/queue/delayed_job"
#   backend = Sunspot::Queue::DelayedJob::Backend.new
#   Sunspot.session = Sunspot::Queue::SessionProxy.new(Sunspot.session, backend)
# end


# To reindex using resque
# unless Rails.env.test? || (defined?($rails_rake_task) && $rails_rake_task && !Rake.application.top_level_tasks.include?('resque:work'))
#   require "sunspot/queue/resque"
#   backend = Sunspot::Queue::Resque::Backend.new
#   Sunspot.session = Sunspot::Queue::SessionProxy.new(Sunspot.session, backend)
# end