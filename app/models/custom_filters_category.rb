# == Schema Information
#
# Table name: custom_filters_categories
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  company_id :integer
#  created_at :datetime
#  updated_at :datetime
#

class CustomFiltersCategory < ActiveRecord::Base
  belongs_to :company
  scoped_to_company

  has_many :custom_filters, -> { order('name ASC') }, foreign_key: :category_id

  validates :name, presence: true
end
