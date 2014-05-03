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
  scoped_to_company
  validates :name, presence: true, uniqueness: true

  # Campaigns-Brands relationship
  has_and_belongs_to_many :campaigns

  has_many :brand_portfolios_brands, dependent: :destroy
  has_many :brand_portfolios, through: :brand_portfolios_brands
  has_many :marques, dependent: :destroy

  scope :not_in_portfolio, lambda{|portfolio| where("brands.id not in (#{BrandPortfoliosBrand.select('brand_id').scoped_by_brand_portfolio_id(portfolio).to_sql})") }
  scope :accessible_by_user, lambda{|user| scoped }

  searchable do
    integer :id

    text :name, stored: true

    string :name
    string :status

    boolean :active

    integer :company_id
  end
  
    def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def status
    self.active? ? 'Active' : 'Inactive'
  end

  def self.report_fields
    {
      name:       { title: 'Name' }
    }
  end
#
    class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      ss = solr_search do
        with(:company_id, params[:company_id])
        with(:id, Campaign.where(id: params[:campaign_id]).joins(:brands).pluck('brands_campaigns.brand_id'))
        with(:id, BrandPortfolio.where(id: params[:brand_portfolio_id]).joins(:brands).pluck('brand_portfolios_brands.brand_id'))
        with(:status, params[:status]) if params.has_key?(:status) and params[:status].present?
        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'brand'
            with :id, value
          else
            with "#{attribute}_ids", value
          end
        end

        if include_facets
          facet :status
        end

        order_by(params[:sorting] || :name, params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end
  end

end
