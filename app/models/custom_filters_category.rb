class CustomFiltersCategory < ActiveRecord::Base
  belongs_to :company
  scoped_to_company

  has_many :custom_filters,-> { order('name ASC')}, :foreign_key => 'category_id'

  validates :name, presence: true
end
