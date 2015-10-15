unless defined?(CLOCKWORK_DEFINED)
  CLOCKWORK_DEFINED = true

  require File.expand_path('../config/boot',        __FILE__)
  require File.expand_path('../config/environment', __FILE__)
  require 'clockwork'

  include Clockwork

  # Runs every 1st of each month
  every 1.day, 'Synching Jameson Locals', at: '6:00', tz: 'Pacific Time (US & Canada)', if: lambda { |t| t.day == 1 } do
    Resque.enqueue JbbWorker, 'JbbFile::JamesonLocalsAccount'
  end

  # Runs every 1st of each month
  every 1.day, 'Synching Top 100 Accounts', at: '6:00', tz: 'Pacific Time (US & Canada)', if: lambda { |t| t.day == 1 } do
    Resque.enqueue JbbWorker, 'JbbFile::TopAccounts'
  end

  # Runs every Thursday at 8:00 am
  every 1.week, 'Synching RSVP', at: 'Thursday 6:00', tz: 'Pacific Time (US & Canada)' do
    Resque.enqueue JbbWorker, 'JbbFile::RsvpReport'
  end
end
