class ProgramMigrationWorker
  @queue = :migration

  def self.perform(company_id, program_id)
    require 'legacy'

    company = Company.find(company_id)
    User.current = company.company_users.order('id asc').first.user
    User.current.current_company_id = company.id
    program = Legacy::Program.find(program_id)
    campaign = program.synchronize(company).local
    if campaign.persisted?
      counter = 0
      batch_size = 20
      total = program.events.count
      while counter < total
        Resque.enqueue(ProgramEventsMigrationWorker, company.id, program_id, campaign.id, counter, batch_size)
        counter += batch_size
      end
    end
  end
end