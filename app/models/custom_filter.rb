# == Schema Information
#
# Table name: custom_filters
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  apply_to   :string(255)
#  filters    :text
#  created_at :datetime
#  updated_at :datetime
#  owner_id   :integer
#  owner_type :string(255)
#  group      :string(255)
#

class CustomFilter < ActiveRecord::Base
  belongs_to :owner, polymorphic: true
  belongs_to :category, class_name: 'CustomFiltersCategory'


  # Required fields
  validates :owner, presence: true
  validates :name, presence: true

  validates :apply_to, presence: true
  validates :filters, presence: true

  attr_accessor :start_date, :end_date, :criteria

  scope :by_type, ->(type) { order('id ASC').where(apply_to: type) }
  scope :user_saved_filters, -> { where(category: nil) }
  scope :not_user_saved_filters, -> { where.not(category: nil) }

  scope :for_company_user, ->(company_user) {
    where(
      '(owner_type=? AND owner_id=?) OR (owner_type=? AND owner_id=?)',
      'Company', company_user.company_id, 'CompanyUser', company_user.id
    )
  }
end
