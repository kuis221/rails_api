# == Schema Information
#
# Table name: brands
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Brand < ActiveRecord::Base
  track_who_does_it

  validates :name, presence: true, uniqueness: true

  # Campaigns-Brands relationship
  has_and_belongs_to_many :campaigns

  has_many :brand_portfolios_brands, dependent: :destroy
  has_many :brand_portfolios, through: :brand_portfolios_brands
  has_many :marques, dependent: :destroy

  scope :not_in_portfolio, lambda{|portfolio| where("brands.id not in (#{BrandPortfoliosBrand.select('brand_id').scoped_by_brand_portfolio_id(portfolio).to_sql})") }
  scope :accessible_by_user, lambda{|user| scoped }

  scope :for_company_campaigns, lambda{|company| joins(:campaigns).where(campaigns: {company_id: company}).order('brands.name') }

  searchable do
    text :name, stored: true
    string :name

    integer :company_id do
      -1
    end

    string :status do
      'Active'
    end

    boolean :active do
      true
    end
  end
end
