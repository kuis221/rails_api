# == Schema Information
#
# Table name: programs
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  brand_id          :integer
#  events_based      :boolean          default(TRUE)
#  hours_based       :boolean          default(FALSE)
#  managed_bar_night :boolean          default(TRUE)
#  brand_ambassador  :boolean          default(FALSE)
#  active            :boolean          default(TRUE)
#  creator_id        :integer
#  updater_id        :integer
#  created_at        :datetime
#  updated_at        :datetime
#

class Legacy::Program  < Legacy::Record
  self.table_name = 'legacy_programs'

  has_and_belongs_to_many :accounts
  has_many :events, inverse_of: :program
  belongs_to :brand

  delegate :name, to: :brand, allow_nil: true, prefix: true

  has_many :data_migrations, as: :remote

  has_one :form_template

  def synchronize(company, attributes = {})
    attributes.merge!(company_id: company.id)
    campaing = ::Campaign.where('lower(name) = ? and company_id=?', name.strip.downcase, company.id).first || ::Campaign.new(name: name.strip)
    migration = data_migrations.find_or_initialize_by_company_id(company.id, local: campaing)
    if migration.local.new_record? || migration.local.form_fields.count == 0
      migration.local.assign_all_global_kpis(false)
    end
    migration.local.assign_attributes(migration_attributes.merge(attributes), without_protection: true)
    migration.save

    synchronize_custom_kpis(company, migration.local)

    # synchronize_venues(company, migration.local)

    migration
  end

  def migration_attributes(_attributes = {})
    {
      brands_list: brand_name,
      aasm_state: (active ? 'active' : 'inactive'),
      created_at: created_at,
      updated_at: updated_at
    }
  end

  def synchronize_custom_kpis(company, campaign)
    form_template.form_fields.custom.each do |field|
      migration = field.metric.synchronize(company, campaign)
      p migration.local.errors.inspect if migration.local.errors.any?
      campaign.add_kpi(migration.local) if migration.local.persisted? && field.metric.is_kpi?
    end
  end

  def synchronize_venues(company, campaign)
    accounts.each do |account|
      migration = account.synchronize(company)
      if migration.local.present? && migration.local.persisted?
        campaign.places << migration.local unless campaign.places.include?(migration.local)
      end
    end
  end
end
