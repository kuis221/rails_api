require 'legacy'

class ProgramMigrationWorker
  @queue = :migration

  def self.perform(program_id, offset, limit)
    company = Company.find_by_name('Legacy Marketing Partners')
    User.current = company.company_users.order('id asc').first.user
    program = Legacy::Program.find(program_id)
    campaign = program.sincronize(company).local
    Legacy::Event.where(program_id: program_id).order('id asc').limit(limit).offset(offset).each do |legacy_event|
      migration = legacy_event.sincronize(company, {campaign_id: campaign.id})
      p migration.local.errors.inspect if migration.local.errors.any?
      p "LevacyEvent[#{legacy_event.id}] => Event[#{migration.local.id}]"
    end
  end
end