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
  has_many      :events
  belongs_to    :brand

  delegate :name, to: :brand, allow_nil: true, prefix: true

  has_many :data_migrations, as: :remote

  def associated_element(company, attributes={})
    @associated_element ||= data_migrations.where(company_id: company).first.try(:local) || begin
        data_migrations.create(company_id: company.id, local: ::Campaign.create(migration_attributes.merge(company_id: company.id), without_protection: true)).local
    end
    @associated_element
  end

  def migration_attributes(attributes={})
    {
      name: name,
      brands_list: brand_name,
      aasm_state: ( active ? 'active' : 'inactive' ),
      created_at: created_at,
      updated_at: updated_at
    }
  end
end