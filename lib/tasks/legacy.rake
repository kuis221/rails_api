require 'legacy'

namespace :legacy do
  namespace :migrate do
    desc 'Sync the events from the LegacyV3 app'
    task :events => :environment do
      Legacy::Migration.synchronize_programs(ENV['PROGRAMS'].split(',').compact.map(&:to_i))
    end

  end
end
