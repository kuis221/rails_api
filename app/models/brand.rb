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
#  company_id    :integer
#  active        :boolean          default("true")
#

class Brand < ActiveRecord::Base
  track_who_does_it

  scoped_to_company

  has_paper_trail

  # Required fields
  validates :name, presence: true, uniqueness: { scope: :company_id, case_sensitive: false }

  # Campaigns-Brands relationship
  has_and_belongs_to_many :campaigns

  has_many :brand_portfolios_brands, dependent: :destroy
  has_many :brand_portfolios, through: :brand_portfolios_brands
  has_many :marques, -> { order 'marques.name ASC' }, autosave: true, dependent: :destroy

  scope :not_in_portfolio, ->(portfolio) { where("brands.id not in (#{BrandPortfoliosBrand.where(brand_portfolio_id: portfolio).select('brand_id').to_sql})") }
  scope :accessible_by_user, ->(user) do
    user.is_admin? ? in_company(user.company_id) : in_company(user.company_id).where(id: user.accessible_brand_ids)
  end

  scope :active, -> { where(active: true) }

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
      name: { title: 'Name' }
    }
  end

  def marques_list
    marques.map(&:name).join ','
  end

  def marques_list=(list)
    marques_names = list.split(',')
    existing_ids = marques.map(&:id)
    marques_names.each do |marque_name|
      marque = Marque.find_or_initialize_by(name: marque_name, brand_id: id)
      marques << marque unless existing_ids.include?(marque.id)
    end
    marques.each { |marque| marque.mark_for_destruction unless marques_names.include?(marque.name) }
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets = false)
      solr_search do
        with(:company_id, params[:company_id])
        with(:id, Campaign.where(id: params[:campaign]).joins(:brands).pluck('brands_campaigns.brand_id')) if params.key?(:campaign) && params[:campaign]
        with(:id, BrandPortfolio.where(id: params[:brand_portfolio]).joins(:brands).pluck('brand_portfolios_brands.brand_id')) if params.key?(:brand_portfolio) && params[:brand_portfolio]
        with(:id, params[:brand]) if params.key?(:brand) && params[:brand].present?
        with(:status, params[:status]) if params.key?(:status) && params[:status].present?

        facet :status if include_facets

        order_by(params[:sorting] || :name, params[:sorting_dir] || :asc)
        paginate page: (params[:page] || 1), per_page: (params[:per_page] || 30)
      end
    end

    def searchable_params
      [brand: [], status: [], brand_portfolio: [], campaign: []]
    end

    # Returns an Array of campaigns ready to be used for a dropdown. Use this
    # to reduce the amount of memory by avoiding the load bunch of activerecord objects.
    # TODO: use pluck(:name, :id) when upgraded to Rails 4
    def for_dropdown
      ActiveRecord::Base.connection.select_all(
        select('brands.name, brands.id').group('1, 2').order('1').to_sql
      ).map { |r| [r['name'], r['id']] }
    end
  end
end
