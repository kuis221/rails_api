# == Schema Information
#
# Table name: campaigns
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  description    :text
#  aasm_state     :string(255)
#  created_by_id  :integer
#  updated_by_id  :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  company_id     :integer
#  first_event_id :integer
#  last_event_id  :integer
#  first_event_at :datetime
#  last_event_at  :datetime
#

class Campaign < ActiveRecord::Base
  include AASM
  include GoalableModel


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

  # Campaigns-Areas relationship
  has_and_belongs_to_many :areas, :order => 'name ASC', :autosave => true

  # Campaigns-Areas relationship
  has_and_belongs_to_many :date_ranges, :order => 'name ASC', :autosave => true

  # Campaigns-Areas relationship
  has_and_belongs_to_many :day_parts, :order => 'name ASC', :autosave => true

  belongs_to :first_event, class_name: 'Event'
  belongs_to :last_event, class_name: 'Event'

  # Campaigns-Users relationship
  has_many :memberships, :as => :memberable
  has_many :users, :class_name => 'CompanyUser', source: :company_user, :through => :memberships,
                   :after_add => :reindex_associated_resource, :after_remove => :reindex_associated_resource

  # Campaigns-Events relationship
  has_many :events, :order => 'start_at ASC', inverse_of: :campaign

  # Campaigns-Teams relationship
  has_many :teamings, :as => :teamable
  has_many :teams, :through => :teamings, :after_add => :reindex_associated_resource, :after_remove => :reindex_associated_resource

  has_many :form_fields, class_name: 'CampaignFormField', order: 'campaign_form_fields.ordering'

  scope :with_goals_for, lambda {|kpi| joins(:goals).where(goals: {kpi_id: kpi}) }

  # Campaigns-Places relationship
  has_many :placeables, as: :placeable
  has_many :places, through: :placeables

  accepts_nested_attributes_for :form_fields

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

    integer :company_user_ids, multiple: true do
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

  def staff
    (users+teams).sort_by &:name
  end

  def areas_and_places
    (areas+places).sort_by &:name
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

  def active_kpis
    @active_kpis ||= form_fields.where('kpi_id is not null').includes(:kpi).map(&:kpi).compact
  end

  def active_field_types
    @active_field_types ||= form_fields.map(&:field_type).uniq
  end


  def survey_brands
    @survey_brands ||= begin
      field = form_fields.scoped_by_kpi_id(Kpi.surveys).first
      brands = []
      if field.present?
        brands = Brand.where(id: field.options['brands']) if field.options.is_a?(Hash) && field.options.has_key?('brands')
      end
      brands || []
    end
  end

  def first_event=(event)
    unless event.nil?
      self.first_event_id = event.id
      self.first_event_at = event.start_at
    end
  end

  def last_event=(event)
    unless event.nil?
      self.last_event_id = event.id
      self.last_event_at = event.start_at
    end
  end

  def assign_all_global_kpis
    assign_attributes({form_fields_attributes: {
      "0" => {"ordering"=>"0", "name"=>"Gender", "field_type"=>"percentage", "kpi_id"=> Kpi.gender.id, "options"=>{"capture_mechanism"=>"integer", "predefined_value"=>""}},
      "1" => {"ordering"=>"1", "name"=>"Age", "field_type"=>"percentage", "kpi_id"=> Kpi.age.id, "options"=>{"capture_mechanism"=>"integer", "predefined_value"=>""}},
      "2" => {"ordering"=>"2", "name"=>"Ethnicity/Race", "field_type"=>"percentage", "kpi_id"=> Kpi.ethnicity.id, "options"=>{"capture_mechanism"=>"integer", "predefined_value"=>""}},
      "3" => {"ordering"=>"3", "name"=>"Expenses", "field_type"=>"expenses", "kpi_id"=> Kpi.expenses.id, "options"=>{"capture_mechanism"=>"currency", "predefined_value"=>""}},
      "4" => {"ordering"=>"4", "name"=>"Surveys", "field_type"=>"surveys", "kpi_id"=> Kpi.surveys.id},
      "5" => {"ordering"=>"5", "name"=>"Photos", "field_type"=>"photos", "kpi_id"=> Kpi.photos.id},
      "6" => {"ordering"=>"6", "name"=>"Videos", "field_type"=>"videos", "kpi_id"=> Kpi.videos.id},
      "7" => {"ordering"=>"7", "name"=>"Impressions", "field_type"=>"number", "kpi_id"=> Kpi.impressions.id, "options"=>{"capture_mechanism"=>"", "predefined_value"=>""}},
      "8" => {"ordering"=>"8", "name"=>"Interactions", "field_type"=>"number", "kpi_id"=> Kpi.interactions.id, "options"=>{"capture_mechanism"=>"", "predefined_value"=>""}},
      "9" => {"ordering"=>"9", "name"=>"Samples", "field_type"=>"number", "kpi_id"=> Kpi.samples.id, "options"=>{"capture_mechanism"=>"", "predefined_value"=>""}},
      "10"=> {"ordering"=>"10", "name"=>"Your Comment", "kpi_id"=> Kpi.comments.id, "field_type"=>"comments"}
    }}, without_protection: true)
    save
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
