# == Schema Information
#
# Table name: campaigns
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  aasm_state    :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :integer
#

class Campaign < ActiveRecord::Base
  include AASM

  # Created_by_id and updated_by_id fields
  track_who_does_it

  scoped_to_company

  attr_accessible :name, :description, :team_ids, :brands_list, :brand_portfolio_ids, :user_ids
  attr_accessor :brands_list

  # Required fields
  validates :name, presence: true
  validates :company_id, presence: true, numericality: true

  # Campaigns-Brands relationship
  has_and_belongs_to_many :brands, :order => 'name ASC', :autosave => true

  # Campaigns-Brand Portfolios relationship
  has_and_belongs_to_many :brand_portfolios, :order => 'name ASC', :autosave => true

  # Campaigns-Users relationship
  has_many :memberships, :as => :memberable
  has_many :users, :class_name => 'CompanyUser', source: :company_user, :through => :memberships,
                   :after_add => :reindex_associated_resource, :after_remove => :reindex_associated_resource

  # Campaigns-Events relationship
  has_many :events, :order => 'start_at ASC'

  # Campaigns-Teams relationship
  has_many :teamings, :as => :teamable
  has_many :teams, :through => :teamings, :after_add => :reindex_associated_resource, :after_remove => :reindex_associated_resource

  # Campaigns-KPIs relationship
  has_and_belongs_to_many :kpis, :after_add => :reindex_associated_resource, :after_remove => :reindex_associated_resource

  # Campaigns-Goals relationship
  has_many :goals

  has_many :form_fields, class_name: 'CampaignFormField', order: 'campaign_form_fields.ordering'
  accepts_nested_attributes_for :form_fields

  scope :with_text, lambda{|text| where('campaigns.name ilike ? or campaigns.description ilike ? ', "%#{text}%", "%#{text}%") }

  aasm do
    state :inactive, :initial => true
    state :active
    state :closed

    event :activate do
      transitions :from => [:inactive, :closed], :to => :active
    end

    event :deactivate do
      transitions :from => :active, :to => :inactive
    end
  end

  searchable do
    text :name, stored: true
    text :description

    string :name
    string :description
    string :status

    integer :company_id
    integer :id

    integer :place_ids, multiple: true do
      []
    end

    string :aasm_state

    integer :user_ids, multiple: true do
      users.map(&:id)
    end
    string :users, multiple: true, references: User do
      users.map{|u| u.id.to_s + '||' + u.name}
    end

    integer :team_ids, multiple: true do
      teams.map(&:id)
    end
    string :teams, multiple: true, references: Team do
      teams.map{|t| t.id.to_s + '||' + t.name}
    end

    integer :brand_ids, multiple: true do
      brands.map(&:id)
    end
    string :brands, multiple: true, references: Brand do
      brands.map{|t| t.id.to_s + '||' + t.name}
    end

    integer :brand_portfolio_ids, multiple: true do
      brand_portfolios.map(&:id)
    end
    string :brand_portfolios, multiple: true, references: BrandPortfolio do
      brand_portfolios.map{|t| t.id.to_s + '||' + t.name}
    end
  end

  def first_event
    events.order('start_at').first
  end

  def last_event
    events.order('start_at').last
  end

  def brands_list=(list)
    brands_names = list.split(',')
    existing_ids = self.brands.map(&:id)
    brands_names.each do |brand_name|
      brand = Brand.find_or_initialize_by_name(brand_name)
      self.brands << brand unless existing_ids.include?(brand.id)
    end
    brands.each{|brand| brand.mark_for_destruction unless brands_names.include?(brand.name) }
  end

  def brands_list
    brands.map(&:name).join ','
  end

  def status
    self.aasm_state.capitalize
  end

  def reindex_associated_resource(resource)
    Sunspot.index(resource)
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      ss = solr_search do
        with(:company_id, params[:company_id])
        with(:user_ids, params[:user]) if params.has_key?(:user) and params[:user].present?
        with(:team_ids, params[:team]) if params.has_key?(:team) and params[:team].present?
        with(:brand_ids, params[:brand]) if params.has_key?(:brand) and params[:brand].present?
        with(:brand_portfolio_ids, params[:brand_portfolio]) if params.has_key?(:brand_portfolio) and params[:brand_portfolio].present?
        with(:status, params[:status]) if params.has_key?(:status) and params[:status].present?

        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'campaign'
            with :id, value
          else
            with "#{attribute}_ids", value
          end
        end

        if include_facets
          facet :users
          facet :teams
          facet :brands
          facet :brand_portfolios
          facet :status
        end

        order_by(params[:sorting] || :name, params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end
  end

end