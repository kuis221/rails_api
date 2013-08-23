# require 'legacy/record'
# require 'legacy/data_migration'
# require 'legacy/address'
# require 'legacy/account'
# require 'legacy/brand'
# require 'legacy/event'
# require 'legacy/event_recap'
# require 'legacy/program'
# require 'legacy/metric'
# require 'legacy/metric_result'

# require 'legacy/metric/whole'
require 'legacy/record'
require 'legacy/metric'
Dir[Rails.root.to_s + "/lib/legacy/**/*.rb"].each do |file|
  require file
end


class Legacy::Migration
  def self.company
    @company ||= Company.find_by_name('Legacy Marketing Partners')
  end
  def self.synchronize_programs(program_ids)
    User.current = company.company_users.order('id asc').first.user
    program_ids.each do |program_id|
      program = Legacy::Program.find(program_id)
      p "Importing #{pluralize(program.events.count, 'event')} from #{program.name}"
      campaign = program.sincronize(company).local
      Legacy::Event.where(program_id: program).find_in_batches do |group|
        group.each do |legacy_event|
          migration = legacy_event.sincronize(company, {campaign_id: campaign.id})
          p migration.local.errors.inspect if migration.local.errors.any?
          p "LevacyEvent[#{legacy_event.id}] => Event[#{migration.local.id}]"
        end
      end
    end
  end
end