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

  attr_accessor :brands_list

  # Required fields
  validates :name, presence: true
  validates :company_id, presence: true, numericality: true

  DATE_FORMAT = /^[0-1]?[0-9]\/[0-3]?[0-9]\/[0-2]0[0-9][0-9]$/
  validates :start_date, format: { with: DATE_FORMAT, message: 'MM/DD/YYYY' }, allow_nil: true
  validates :end_date, format: { with: DATE_FORMAT, message: 'MM/DD/YYYY' }, allow_nil: true
  validates :end_date, presence: true, if: :start_date
  validates :start_date, presence: true, if: :end_date

  validates_date :start_date, before: :end_date,  allow_nil: true, allow_blank: true, before_message: 'must be before'
  validates_date :end_date, :on_or_after => :start_date, allow_nil: true, allow_blank: true, on_or_after_message: ''

  # Campaigns-Brands relationship
  has_and_belongs_to_many :brands, :order => 'name ASC', :autosave => true

  # Campaigns-Brand Portfolios relationship
  has_and_belongs_to_many :brand_portfolios, :order => 'name ASC', :autosave => true

  # Campaigns-Areas relationship
  has_and_belongs_to_many :areas, :order => 'name ASC', :autosave => true, after_remove: :clear_locations_cache, after_add: :clear_locations_cache

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
  scope :accessible_by_user, lambda {|company_user| company_user.is_admin? ? scoped() : where(id: company_user.accessible_campaign_ids) }
  scope :active, lambda { where(aasm_state: 'active') }

  # Campaigns-Places relationship
  has_many :placeables, as: :placeable
  has_many :places, through: :placeables, after_remove: :clear_locations_cache, after_add: :clear_locations_cache

  # Attached Documents
  has_many :documents, conditions: {asset_type: :document}, class_name: 'AttachedAsset', :as => :attachable, inverse_of: :attachable, order: "created_at DESC"

  accepts_nested_attributes_for :form_fields

  aasm do
    state :active, :initial => true
    state :inactive
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

    string :name
    string :status

    integer :company_id
    integer :id

    integer :place_ids, multiple: true

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

  def has_date_range?
    start_date.present? && end_date.present?
  end

  def staff
    (staff_users+teams).sort_by &:name
  end

  def staff_users
    staff_users = (
      users +
      CompanyUser.scoped_by_company_id(company_id).joins(:brands).where(brands: {id: brand_ids}) +
      CompanyUser.scoped_by_company_id(company_id).joins(:brand_portfolios).where(brand_portfolios: {id: brand_portfolio_ids})
    ).uniq
  end

  def areas_and_places
    (areas+places).sort_by &:name
  end

  def place_allowed_for_event?(place)
    !geographically_restricted? ||
    place.locations.pluck('locations.id').any?{|location| accessible_locations.include?(location)} ||
    places.map(&:id).include?(place.id) ||
    areas.map(&:place_ids).flatten.include?(place.id)
  end

  def accessible_locations
    Rails.cache.fetch("campaign_locations_#{id}") do
      (
        areas.reorder(nil).joins(:places).where(places: {is_location: true}).pluck('places.location_id') +
        places.where(is_location: true).reorder(nil).pluck('places.location_id')
      ).map(&:to_i)
    end
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

  def associated_brands
    brands + brand_portfolios.includes(:brands).map(&:brands).flatten
  end

  def status
    self.aasm_state.capitalize
  end

  def reindex_associated_resource(resource)
    Sunspot.index(resource)
  end

  def active_kpis
    @active_kpis ||= (form_fields.where('kpi_id is not null').includes(:kpi).map(&:kpi) + [Kpi.events, Kpi.promo_hours]).compact
  end

  def custom_kpis
    @custom_kpis ||= (form_fields.where("kpi_id is not null AND module = 'custom'").joins(:kpi).map(&:kpi)).compact
  end

  def active_field_types
    @active_field_types ||= form_fields.map(&:field_type).uniq
  end

  # Returns true if there is any area or place associated to the campaign
  def geographically_restricted?
    (self.areas.loaded? ? self.areas.any? : self.areas.count > 0 ) ||
    (self.places.loaded? ? self.places.any? : self.places.count > 0 )
  end

  def add_kpi(kpi)
    field = form_fields.where(kpi_id: kpi).first

    # Make sure the kpi is not already assigned to the campaign
    if field.nil?
      ordering = form_fields.select('max(ordering) as ordering').reorder(nil).first.ordering || 0
      field = form_fields.create({kpi: kpi, field_type: kpi.kpi_type, name: kpi.name, ordering: ordering + 1, options: {capture_mechanism: kpi.capture_mechanism}}, without_protection: true)

      # Update any preview results captured for this kpi using the new
      # created field
      if field.persisted?
        EventResult.joins(:event).where(events: {campaign_id: self.id}, kpi_id: kpi).update_all(form_field_id: field.id)
      end
    end

    field
  end

  def form_field_for_kpi(kpi)
    form_fields.detect{|field| field.kpi_id == kpi.id}
  end

  def survey_statistics
    answers_scope = SurveysAnswer.joins(survey: :event).where(events:{campaign_id: self.id}, brand_id: survey_brands.map(&:id), question_id: [1,3,4])
    total_surveys = answers_scope.select('distinct(surveys.id)').count
    answers_scope = answers_scope.select('count(surveys_answers.id) as counter,surveys_answers.answer, surveys_answers.question_id, surveys_answers.brand_id').group('surveys_answers.answer, surveys_answers.question_id, surveys_answers.brand_id')
    brands_map = Hash[survey_brands.map{|b| [b.id, b.name] }]
    stats = {}
    answers_scope.each do |answer|
      stats["question_#{answer.question_id}"] ||= {}
      stats["question_#{answer.question_id}"][answer.answer] ||= {}
      stats["question_#{answer.question_id}"][answer.answer][brands_map[answer.brand_id]] ||= {count: 0, avg: 0.0}
      stats["question_#{answer.question_id}"][answer.answer][brands_map[answer.brand_id]][:count] = answer.counter.to_i
      stats["question_#{answer.question_id}"].each{|a, brands| brands.each{|b, s| s[:avg] = s[:count]*100.0/total_surveys} }
    end

    stats
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

  def assign_all_global_kpis(autosave = true)
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
    save if autosave
  end

  def clear_locations_cache(area)
    Rails.cache.delete("campaign_locations_#{self.id}")
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      ss = solr_search do
        with(:company_id, params[:company_id])
        with(:company_user_ids, params[:user]) if params.has_key?(:user) and params[:user].present?
        with(:team_ids, params[:team]) if params.has_key?(:team) and params[:team].present?
        with(:brand_ids, params[:brand]) if params.has_key?(:brand) and params[:brand].present?
        with(:brand_portfolio_ids, params[:brand_portfolio]) if params.has_key?(:brand_portfolio) and params[:brand_portfolio].present?
        with(:status, params[:status]) if params.has_key?(:status) and params[:status].present?

        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'campaign'
            with :id, value
          when 'venue'
            with :place_ids, Venue.find(value).place_id
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
