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
#  active        :boolean          default(TRUE)
#

class Brand < ActiveRecord::Base
  track_who_does_it

  scoped_to_company

  # Required fields
  validates :name, presence: true, uniqueness: {scope: :company_id, case_sensitive: false}

  # Campaigns-Brands relationship
  has_and_belongs_to_many :campaigns

  has_many :brand_portfolios_brands, dependent: :destroy
  has_many :brand_portfolios, through: :brand_portfolios_brands
  has_many :marques, -> { order 'name ASC' }, :autosave => true, dependent: :destroy

  scope :not_in_portfolio, ->(portfolio) { where("brands.id not in (#{BrandPortfoliosBrand.where(brand_portfolio_id: portfolio).select('brand_id').to_sql})") }
  scope :accessible_by_user, ->(user) { all }

  scope :active, ->{ where(:active => true) }

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
    existing_ids = self.marques.map(&:id)
    marques_names.each do |marque_name|
      marque = Marque.find_or_initialize_by(name: marque_name, brand_id: id)
      self.marques << marque unless existing_ids.include?(marque.id)
    end
    marques.each{|marque| marque.mark_for_destruction unless marques_names.include?(marque.name) }
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      solr_search do
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

    # Returns an Array of campaigns ready to be used for a dropdown. Use this
    # to reduce the amount of memory by avoiding the load bunch of activerecord objects.
    # TODO: use pluck(:name, :id) when upgraded to Rails 4
    def for_dropdown
      ActiveRecord::Base.connection.select_all(
        self.select("brands.name, brands.id").group('1, 2').order('1').to_sql
      ).map{|r| [r['name'], r['id']] }
    end
  end

end
