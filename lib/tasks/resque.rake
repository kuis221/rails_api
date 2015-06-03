require 'resque/tasks'


namespace :resque do
  # this task will get called before resque:pool:setup
  # and preload the rails environment in the pool manager
  task setup: :environment do
    require 'sunspot/queue/resque'
    Resque.before_fork = proc { ActiveRecord::Base.connection.disconnect! }
    Resque.after_fork do
      config = ActiveRecord::Base.configurations[Rails.env] ||
        Rails.application.config.database_configuration[Rails.env]
      config['adapter'] = 'postgis'
      ActiveRecord::Base.establish_connection(config)
    end
  end

  desc "Kill all stale workers running longer than X seconds"
  task kill_stale: :environment do
    kill_time = ENV['kill_time'] || 7200  # Default 2 hours
    Resque.workers.each do |w|
      w.unregister_worker if w.processing['run_at'] &&
                             Time.now - w.processing['run_at'].to_time > kill_time
    end
  end

  desc "Kill all workers running longer than 25 hours"
  task kill_zombies: :environment do
    Resque.workers.each { |w| w.unregister_worker if w.started < 25.hours.ago }
  end
end
