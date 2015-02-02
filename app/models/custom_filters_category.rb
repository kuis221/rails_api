class CustomFiltersCategory < ActiveRecord::Base
  belongs_to :company
  scoped_to_company

  has_many :customFilters,-> { order('name ASC')}, :foreign_key => 'category_id'

  validates :name, presence: true

  scope :for_company_user, ->(company_user) {
    where(
      '(company_id=?)', company_user.company_id
    )
  }
end
