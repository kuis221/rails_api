class BrandPortfolio < ActiveRecord::Base
  # Created_by_id and updated_by_id fields
  track_who_does_it

  scoped_to_company

  attr_accessible :name, :active

  validates :name, presence: true, uniqueness: {scope: :company_id}
  validates :company_id, presence: true

  has_and_belongs_to_many :brands
end
