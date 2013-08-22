require 'legacy'

namespace :legacy do
  namespace :migrate do

    task :prepare_migration => :environment do
      @company = Company.find(4)
      @program = Legacy::Program.find(51)
      @campaign = @program.associated_element(@company)
      p "Preparing to import data into #{@company.name}"
    end

    desc 'Sync the events from the LegacyV3 app'
    task :events => :prepare_migration do
      Legacy::Event.where(program_id: @program).find_in_batches do |group|
        group.each do |legacy_event|
          migration = legacy_event.sincronize(@company, {campaign_id: @campaign.id})
          p migration.local.errors.inspect if migration.local.errors.any?
          p "LevacyEvent[#{legacy_event.id}] => Event[#{migration.local.id}]"
        end
      end
    end

  end
end
