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

  has_many :data_migrations, as: :remote

  def sincronize(company, attributes={})
    attributes.merge!({company_id: company.id})
    migration = data_migrations.find_or_initialize_by_company_id(company.id, local: ::Event.new)
    migration.local.assign_attributes migration_attributes.merge(attributes), without_protection: true

    account_migration = account.sincronize(company)
    migration.local.place = account_migration.local
    migration.local.place.is_custom_place = true if account_migration.local.present? and account_migration.local.place_id.nil?
    if migration.save
      event_recap_attributes(migration.local)
      migration.local.save
    end

    migration
  end

  def migration_attributes(attributes={})
    {
      start_at: start_at,
      end_at: end_at,
      active: active,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  def event_recap_attributes(event)
    event.aasm_state = event_recap.new_record? ? 'unsent' : event_recap.state

    # Consumer Impressions
    result = event.result_for_kpi(Kpi.impressions)
    result.value = event_recap.result_for_metric(Metric.system.find_by_name('# Consumer Impressions')).try(:scalar_value)
    result.value = result.value.to_s unless result.value.nil?

    # Consumers Sampled
    result = event.result_for_kpi(Kpi.samples)
    result.value = event_recap.result_for_metric(Metric.system.find_by_name('# Consumers Sampled')).try(:scalar_value)
    result.value = result.value.to_s unless result.value.nil?

    # Consumers Interactions
    result = event.result_for_kpi(Kpi.interactions)
    result.value = event_recap.result_for_metric(Metric.system.find_by_name('# Consumer Interactions')).try(:scalar_value)
    result.value = result.value.to_s unless result.value.nil?

    # Gender
    # [[1, "Male"], [2, "Female"]]
    kpi_results = event.result_for_kpi(Kpi.gender)
    values = event_recap.result_for_metric(Metric.system.find_by_name('Gender')).try(:value)
    kpi_results.detect{|r| r.kpis_segment.text == 'Male' }.try('value=', values[1].to_s)
    kpi_results.detect{|r| r.kpis_segment.text == 'Female' }.try('value=', values[2].to_s)

    # Age
    # [3, "LDA-27"], [4, "28-35"], [5, "36-44"], [6, "45-55"], [7, "56+"]]
    kpi_results = event.result_for_kpi(Kpi.age)
    values = event_recap.result_for_metric(Metric.system.find_by_name('Age')).try(:value)
    kpi_results.detect{|r| r.kpis_segment.text == '18 – 24' }.try('value=', values[3].to_s)
    kpi_results.detect{|r| r.kpis_segment.text == '25 – 34' }.try('value=', values[4].to_s)
    kpi_results.detect{|r| r.kpis_segment.text == '35 – 44' }.try('value=', values[5].to_s)
    kpi_results.detect{|r| r.kpis_segment.text == '45 – 54' }.try('value=', values[6].to_s)
    kpi_results.detect{|r| r.kpis_segment.text == '55 – 64' }.try('value=', values[7].to_s)

    # Ethnicity
    # [[9, "African American"], [10, "Asian"], [11, "Hispanic"], [12, "Other"], [8, "General Market"]]
    kpi_results = event.result_for_kpi(Kpi.ethnicity)
    values = event_recap.result_for_metric(Metric.system.find_by_name('Demographic')).try(:value)
    kpi_results.detect{|r| r.kpis_segment.text == 'Asian' }.try('value=', values[10].to_s)
    kpi_results.detect{|r| r.kpis_segment.text == 'Black / African American' }.try('value=', values[9].to_s)
    kpi_results.detect{|r| r.kpis_segment.text == 'Hispanic / Latino' }.try('value=', values[11].to_s)
    kpi_results.detect{|r| r.kpis_segment.text == 'White' }.try('value=', values[8].to_s)

  end
end
