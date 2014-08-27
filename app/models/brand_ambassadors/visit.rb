class BrandAmbassadors::Visit < ActiveRecord::Base
  self.table_name = 'brand_ambassadors_visits'

  belongs_to :company_user
  belongs_to :company

  scoped_to_company

  validates :name, presence: true
  validates :start_date, presence: true
  validates :start_date, presence: true, date: { on_or_after: :start_date, message: 'must be after' }

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end
end
