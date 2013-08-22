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

  has_many :data_migrations, as: :remote

  def sincronize(company, attributes={})
    attributes.merge!({company_id: company.id})
    migration = data_migrations.find_or_initialize_by_company_id(company.id, local: ::Event.new)
    migration.local.assign_attributes(migration_attributes.merge(attributes), without_protection: true)
    account_migration = account.sincronize(company)
    migration.local.place = account_migration.local
    migration.local.place.is_custom_place = true if account_migration.local.present? and account_migration.local.place_id.nil?
    migration.save
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
end
