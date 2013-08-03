unless $rails_rake_task
  require "sunspot/queue/delayed_job"
  backend = Sunspot::Queue::DelayedJob::Backend.new
  Sunspot.session = Sunspot::Queue::SessionProxy.new(Sunspot.session, backend)
end