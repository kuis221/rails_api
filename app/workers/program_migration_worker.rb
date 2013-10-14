
class ProgramMigrationWorker
  @queue = :migration

  def self.perform(company_id, program_id, campaign_id, offset, limit)
    require 'legacy'

    company = Company.find(company_id)
    User.current = company.company_users.order('id asc').first.user
    program = Legacy::Program.find(program_id)
    Legacy::Event.where(program_id: program_id).order('id asc').limit(limit).offset(offset).each do |legacy_event|
      migration = legacy_event.synchronize(company, {campaign_id: campaign_id})
    end
  end
end