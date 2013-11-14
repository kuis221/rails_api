# == Schema Information
#
# Table name: events
#
#  id                  :integer          not null, primary key
#  program_id          :integer
#  account_id          :integer
#  start_at            :datetime
#  end_at              :datetime
#  notes               :text
#  staff               :string(255)
#  deactivation_reason :string(255)
#  event_type_id       :integer
#  confirmed           :boolean          default(TRUE)
#  active              :boolean          default(TRUE)
#  creator_id          :integer
#  updater_id          :integer
#  created_at          :datetime
#  updated_at          :datetime
#  drink_special       :boolean          default(FALSE), not null
#  market_id           :integer
#

class Legacy::Event < Legacy::Record
  belongs_to    :program
  belongs_to    :account
  has_one       :event_recap
  has_many      :receipts
  has_many      :photos, :as => :photographable

  has_many :data_migrations, as: :remote

  def synchronize(company, attributes={})
    attributes.merge!({company_id: company.id})
    migration = data_migrations.find_or_initialize_by_company_id(company.id, local: ::Event.new)

    # Migrate the account to a Place
    account_migration = account.synchronize(company)
    migration.local.place = account_migration.local
    migration.local.place.is_custom_place = true if account_migration.local.present? and account_migration.local.place_id.nil?

    # Set Event attributes, the start/end dates depends on the places, so this have to be done after
    # the account migration
    migration.local.assign_attributes migration_attributes(migration.local.place).merge(attributes), without_protection: true


    if migration.save(validate: false)
      event_recap_attributes(migration.local)
      tries = 3
      begin
        migration.local.save(validate: false)
      rescue AWS::S3::Errors::RequestTimeout => e
        sleep(3)
        retry unless (tries -= 1).zero?
      end
      Resque.enqueue(PhotoMigrationWorker, self.id, migration.local.id) if self.photos.count > 0
    end

    migration
  end

  def migration_attributes(place)
    localized_start_at = self.start_at
    localized_end_at = self.end_at
    if place.latitude
      begin
        tz = NearestTimeZone.to(place.latitude, place.longitude)
        localized_start_at = Timeliness.parse(self.start_at.utc.strftime('%Y-%m-%d %H:%M:%S'), zone: tz)
        localized_end_at = Timeliness.parse(self.end_at.utc.strftime('%Y-%m-%d %H:%M:%S'), zone: tz)
      rescue Exception => e

      end
    end
    {
      start_at: localized_start_at,
      end_at: localized_end_at,
      active: active,
      created_at: created_at,
      updated_at: updated_at,
      aasm_state: event_recap.state == 'new' ? 'unsent' : event_recap.state
    }
  end

  def photos
    Legacy::Photo.where(photographable_type: 'Event', photographable_id: self.id)
  end

  def event_recap_attributes(event)
    active_kpis = event.campaign.active_kpis

    # Event summary
    result = event_recap.result_for_metric(Metric.system.find_by_name(FormField::SUMMARY_FIELD))
    # If the summary was not found for the system metric, check for the program metric
    result = event_recap.result_for_metric(Metric.for_program(program).find_by_name(FormField::SUMMARY_FIELD)) if result.nil? || result.new_record?
    event.summary = result.try(:value)

    # Comments
    FormField::COMMENTS_FIELDS.each do |metric_name|
      result = event_recap.result_for_metric(Metric.system.find_by_name(metric_name))
      # If the comment was not found for the system metric, check for the program metric
      result = event_recap.result_for_metric(Metric.for_program(program).find_by_name(metric_name)) if result.nil? || result.new_record?
      if result.present?
        migration = result.data_migrations.find_or_initialize_by_company_id(event.company_id, local: ::Comment.new)
        migration.local.content = result.value
        migration.local.commentable = event
        migration.save
      end
    end

    # Contacts
    if event.contacts.empty?
      FormField::CONTACTS_FIELDS.each do |metric_name|
        result = event_recap.result_for_metric(Metric.system.find_by_name(metric_name))
        # If the contact was not found for the system metric, check for the program metric
        result = event_recap.result_for_metric(Metric.for_program(program).find_by_name(metric_name)) if result.nil? || result.new_record?
        if result.present?
          unless result.value.nil? || result.value.strip == ''
            (first_name,last_name) = result.value.split(' ', 2)
            contact = Contact.find_or_initialize_by_company_id_and_first_name_and_last_name(event.company_id, first_name, last_name)
            contact.title = metric_name.gsub(/\s*[0-9]+$/,'')
            contact.save(validate: false) if contact.new_record?
            event.contact_events.build(contactable: contact)
          end
        end
      end
    end


    # Event Team
    if event.users.empty?
      FormField::TEAM_FIELDS.each do |metric_name|
        result = event_recap.result_for_metric(Metric.system.find_by_name(metric_name))
        # If the contact was not found for the system metric, check for the program metric
        result = event_recap.result_for_metric(Metric.for_program(program).find_by_name(metric_name)) if result.nil? || result.new_record?
        if result.present?
          unless result.value.nil? || result.value.strip == ''
            (first_name,last_name) = result.value.split(' ', 2)
            if first_name && last_name
              user = CompanyUser.scoped_by_company_id(event.company_id).joins(:user).where('lower(users.first_name)=? and lower(users.last_name)=?', first_name.downcase.strip, last_name.downcase.strip).first
              event.memberships.build(company_user: user) if user.present?
            end
          end
        end
      end
    end

    # Consumer Impressions
    if active_kpis.include?(Kpi.impressions)
      result = event.result_for_kpi(Kpi.impressions)
      result.value = event_recap.result_for_metric(Metric.system.find_by_name('# Consumer Impressions')).try(:scalar_value)
      result.value = result.value.to_s unless result.value.nil?
    end

    # Consumers Sampled
    if active_kpis.include?(Kpi.samples)
      result = event.result_for_kpi(Kpi.samples)
      result.value = event_recap.result_for_metric(Metric.system.find_by_name('# Consumers Sampled')).try(:scalar_value)
      result.value = result.value.to_s unless result.value.nil?
    end

    # Consumers Interactions
    if active_kpis.include?(Kpi.interactions)
      result = event.result_for_kpi(Kpi.interactions)
      result.value = event_recap.result_for_metric(Metric.system.find_by_name('# Consumer Interactions')).try(:scalar_value)
      result.value = result.value.to_s unless result.value.nil?
    end

    # Gender
    # [[1, "Male"], [2, "Female"]]
    if active_kpis.include?(Kpi.gender)
      kpi_results = event.result_for_kpi(Kpi.gender)
      values = event_recap.result_for_metric(Metric.system.find_by_name('Gender')).try(:value)
      kpi_results.detect{|r| r.kpis_segment.text == 'Male' }.try('value=', values[1].to_s)
      kpi_results.detect{|r| r.kpis_segment.text == 'Female' }.try('value=', values[2].to_s)
    end

    # Age
    # [[3, "LDA-27"], [4, "28-35"], [5, "36-44"], [6, "45-55"], [7, "56+"]]
    if active_kpis.include?(Kpi.age)
      kpi_results = event.result_for_kpi(Kpi.age)
      values = event_recap.result_for_metric(Metric.system.find_by_name('Age')).try(:value)
      kpi_results.detect{|r| r.kpis_segment.text == '18 – 24' }.try('value=', values[3].to_s)
      kpi_results.detect{|r| r.kpis_segment.text == '25 – 34' }.try('value=', values[4].to_s)
      kpi_results.detect{|r| r.kpis_segment.text == '35 – 44' }.try('value=', values[5].to_s)
      kpi_results.detect{|r| r.kpis_segment.text == '45 – 54' }.try('value=', values[6].to_s)
      kpi_results.detect{|r| r.kpis_segment.text == '55 – 64' }.try('value=', values[7].to_s)
    end

    # Ethnicity
    # [[9, "African American"], [10, "Asian"], [11, "Hispanic"], [12, "Other"], [8, "General Market"]]
    if active_kpis.include?(Kpi.ethnicity)
      kpi_results = event.result_for_kpi(Kpi.ethnicity)
      values = event_recap.result_for_metric(Metric.system.find_by_name('Demographic')).try(:value)
      kpi_results.detect{|r| r.kpis_segment.text == 'Asian'                    }.try('value=', values[10].to_s)
      kpi_results.detect{|r| r.kpis_segment.text == 'Black / African American' }.try('value=', values[9].to_s)
      kpi_results.detect{|r| r.kpis_segment.text == 'Hispanic / Latino'        }.try('value=', values[11].to_s)
      kpi_results.detect{|r| r.kpis_segment.text == 'White'                    }.try('value=', values[8].to_s)
    end

    # Custom KPIs
    program.form_template.form_fields.custom.each do |field|
      migration = Legacy::DataMigration.for_metric(field.metric).first
      if migration.present? and migration.local.present?
        result = event.result_for_kpi(migration.local) if migration.local.is_a?(Kpi)
        result = event.results_for([migration.local]).first if migration.local.is_a?(CampaignFormField)
        if migration.local.is_segmented?
          values = event_recap.result_for_metric(field.metric).try(:value)
          values.each do |option_id, value|
            value = value.to_i if !value.nil? and migration.local.capture_mechanism == 'integer'
            metric_option = field.metric.metric_options.find(option_id)
            result.detect{|r| r.kpis_segment.text == metric_option.name }.try('value=',  value.to_s) if metric_option.present?
          end
        else
          metric_result = event_recap.result_for_metric(field.metric).try(:value)
          unless metric_result.nil?
            if field.metric.type == 'Metric::Boolean'
              result.value = migration.local.kpis_segments.detect{|s| s.text == ['No', 'Yes'][metric_result]}.try(:id)
            elsif field.metric.type == 'Metric::Select'
              if metric_result > 0
                begin
                  selected_option = field.metric.metric_options.find(metric_result).try(:name)
                  result.value = migration.local.kpis_segments.detect{|s| s.text == selected_option}.try(:id)
                rescue ActiveRecord::RecordNotFound => e
                  result.value = nil
                end
              end
            elsif field.metric.type == 'Metric::Multi'
              begin
                selected_options = field.metric.metric_options.find(metric_result).map(&:name)
                result.value = migration.local.kpis_segments.select{|s| selected_options.include?(s.text) }.map(&:id)
              rescue ActiveRecord::RecordNotFound => e
                result.value = nil
              end
            elsif migration.local.is_a?(Kpi) && migration.local.kpi_type == 'count'
              if metric_result.is_a?(Array)
                result.value = metric_result.join(',')
              else
                result.value = metric_result
              end
            else
              if migration.local.capture_mechanism == 'integer'
                result.value = metric_result.try(:to_i).try(:to_s)
              else
                result.value = metric_result
              end
            end
          end
        end
      end
    end


    # Expenses
    tries = 5
    begin
      spend_metric = Metric.scoped_by_program_id(program).scoped_by_type('Metric::BarSpend').first
      value = event_recap.result_for_metric(spend_metric).try(:value)

      bar_spend = event.event_expenses.where(name: 'bar spend').first || event.event_expenses.build({name: 'bar spend'})
      bar_spend.amount = value[Metric::Tab::TAB]
      tip = event.event_expenses.where(name: 'tip').first || event.event_expenses.build({name: 'tip'})
      tip.amount = value[Metric::Tab::TIP]

      # if receipt = receipts.first
      #   bar_spend.build_receipt if bar_spend.receipt.nil?
      #   bar_spend.receipt.file = receipt.file if bar_spend.receipt.file_file_size != receipt.file_file_size
      # end
    rescue AWS::S3::Errors::RequestTimeout => e
      unless (tries -= 1).zero?
        sleep(3)
        retry
      else
        raise
      end
    end

  end

  def synch_photos(event)
    # Photos
    photos.each do |photo|
      tries = 5
      begin
        migration = photo.data_migrations.find_or_initialize_by_company_id(event.company_id)
        migration.local ||= event.photos.build
        migration.local.file = photo.file if photo.file_file_size != migration.local.file_file_size
        migration.local.active = photo.active
        migration.local.processed = true
        migration.save
        p migration.local.errors if  migration.local.errors.any?
      rescue AWS::S3::Errors::RequestTimeout => e
        unless (tries -= 1).zero?
          sleep(3)
          retry
        else
          raise
        end
      end
    end

    # Receipts
    tries = 5
    begin
      spend_metric = Metric.scoped_by_program_id(program).scoped_by_type('Metric::BarSpend').first
      value = event_recap.result_for_metric(spend_metric).try(:value)

      bar_spend = event.event_expenses.where(name: 'bar spend').first

      if bar_spend.present? && receipt = receipts.first
        bar_spend.build_receipt if bar_spend.receipt.nil?
        bar_spend.receipt.file = receipt.file if bar_spend.receipt.file_file_size != receipt.file_file_size
        bar_spend.save
      end
    rescue AWS::S3::Errors::RequestTimeout => e
      unless (tries -= 1).zero?
        sleep(3)
        retry
      else
        raise
      end
    end

  end
end
