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




module Legacy
  S3_CONFIGS = {
    'access_key_id' => 'AKIAIIGAIZKQFFQDIXZA',
    'secret_access_key' => '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',
    'bucket_name' => 'legacy-v3',
    'options' => {
      'use_ssl' => true,
      'persistent' => false
    },
  }

  PAPERCLIP_SETTINGS = {
    :s3_credentials => (lambda do |attachment| {
      :access_key_id =>  Legacy::S3_CONFIGS['access_key_id'],
      :secret_access_key => Legacy::S3_CONFIGS['secret_access_key'],
      :bucket => Legacy::S3_CONFIGS['bucket_name'],
    }
    end),
    :storage => :s3
  }


  class Migration
    def self.company
      @company ||= Company.find_by_name('Legacy Marketing Partners')
    end
    def self.synchronize_programs(program_ids)
      User.current = company.company_users.order('id asc').first.user
      program_ids.each do |program_id|
        program = Legacy::Program.find(program_id)
        counter = 1
        total = program.events.count
        p "Importing #{pluralize(total, 'event')} from #{program.name}"
        campaign = program.sincronize(company).local
        Legacy::Event.where(program_id: program).find_in_batches(batch_size: 300) do |group|
          group.each do |legacy_event|
            migration = legacy_event.sincronize(company, {campaign_id: campaign.id})
            p migration.local.errors.inspect if migration.local.errors.any?
            p "#{counter} of #{total}: LevacyEvent[#{legacy_event.id}] => Event[#{migration.local.id}]"
            counter+=1
          end
        end
      end
    end
    def self.api_client
      @client ||= GooglePlaces::Client.new(GOOGLE_API_KEY)
    end
  end

end

Paperclip.interpolates :dashed_style do |attachment, style|
  if style.to_sym == :original
    ""
  else
    "_#{style}"
  end
end



# require 'legacy/metric/whole'
require 'legacy/record'
require 'legacy/metric'
Dir[Rails.root.to_s + "/lib/legacy/**/*.rb"].each do |file|
  require file
end
