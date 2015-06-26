# == Schema Information
#
# Table name: activities
#
#  id               :integer          not null, primary key
#  activity_type_id :integer
#  activitable_id   :integer
#  activitable_type :string(255)
#  campaign_id      :integer
#  active           :boolean          default(TRUE)
#  company_user_id  :integer
#  activity_date    :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Activity < ActiveRecord::Base
  belongs_to :activity_type
  belongs_to :activitable, polymorphic: true
  belongs_to :company_user
  belongs_to :campaign

  has_many :results, class_name: 'FormFieldResult', inverse_of: :resultable, as: :resultable

  validates :activity_type_id, numericality: true, presence: true,
    inclusion: { in: :valid_activity_type_ids }

  validates :campaign_id, presence: true, numericality: true
  validates :activitable_id, presence: true, numericality: true
  validates :activitable_type, presence: true
  validates :company_user_id, presence: true, numericality: true
  validates :activity_date, presence: true

  scope :active, -> { where(active: true) }

  scope :with_results_for, ->(fields) {
    select('DISTINCT activities.*').
    joins(:results).
    where(form_field_results: { form_field_id: fields }).
    where('form_field_results.value is not NULL AND form_field_results.value !=\'\'')
  }

  scope :accessible_by_user, ->(user) { in_company(user.company) }

  after_initialize :set_default_values

  delegate :company_id, :company, :place, :place_id, to: :activitable, allow_nil: true
  delegate :td_linx_code, :name, :city, :state, :zipcode, :street_number, :route, :formatted_address,
           to: :place, allow_nil: true, prefix: true
  delegate :name, to: :campaign, allow_nil: true, prefix: true
  delegate :full_name, to: :company_user, allow_nil: true, prefix: true
  delegate :name, :description, to: :activity_type, allow_nil: true, prefix: true
  delegate :form_fields, to: :activity_type

  accepts_nested_attributes_for :results, allow_destroy: true

  before_validation :delegate_campaign_id_from_event

  searchable do
    integer :company_id
    integer :campaign_id
    integer :activity_type_id
    integer :company_user_id
    integer :place_id
    integer :location, multiple: true do
      locations_for_index
    end
    integer :activitable_id
    string :activitable_type
    string :activitable do
      "#{activitable_type}#{activitable_id}"
    end
    date :activity_date
    string :status
    join(:events_active, target: Event, type: :boolean, join: { from: :id, to: :activitable_id }, as: :active_b)
  end

  def self.in_company(company)
    joins('LEFT JOIN events ue ON activitable_type=\'Event\' AND ue.id=activitable_id').
    joins('LEFT JOIN venues uv ON activitable_type=\'Venue\' AND uv.id=activitable_id').
    where('ue.company_id=:company OR uv.company_id=:company', company: company)
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def form_field_results
    activity_type.form_fields.map do |field|
      result = results.find { |r| r.form_field_id == field.id } || results.build(form_field_id: field.id)
      result.form_field = field
      result
    end
  end

  def results_for(fields)
    fields.map do |field|
      result = results.select { |r| r.form_field_id == field.id }.first || results.build(form_field_id: field.id)
      result.form_field = field
      result
    end
  end

  def photos
    AttachedAsset.where(
      id: results.joins(:form_field, :attached_asset)
            .select('attached_assets.id')
            .where(form_fields: { type: ActivityType::PHOTO_FIELDS_TYPES })
            .where.not(form_field_results: { value: nil })
            .where.not(form_field_results: { value: '' })
    )
  end

  def valid_activity_type_ids
    if campaign.present?
      campaign.activity_type_ids
    elsif company.present?
      company.activity_type_ids
    else
      []
    end
  end

  def locations_for_index
    place.locations.pluck('locations.id') if place.present?
  end

  def status
    self.active? ? 'Active' : 'Inactive'
  end

  class << self
    def do_search(params)
      solr_search(include: [:campaign, :activity_type, company_user: :user]) do
        with :company_id, params[:company_id]
        with :campaign_id, params[:campaign] if params.key?(:campaign) && params[:campaign].present?
        with :activity_type_id, params[:activity_type] if params.key?(:activity_type) && params[:activity_type].present?
        with :company_user_id, params[:user] if params.key?(:user) && params[:user].present?
        with(:status, params[:status]) if params.key?(:status) && params[:status].present?

        if params.key?(:brand) && params[:brand].present?
          campaign_ids = Campaign.with_brands(params[:brand]).pluck('campaigns.id')
          with 'campaign_id', campaign_ids + [0]
        end

        company_user = params[:current_company_user]
        if company_user.present? && !company_user.role.is_admin?
          with(:campaign_id, company_user.accessible_campaign_ids + [0])
          any_of do
            locations = company_user.accessible_locations
            places_ids = company_user.accessible_places
            with(:place_id, places_ids + [0])
            with(:location, locations + [0])
          end
        end

        with :place_id, Venue.where(id: params[:venue]).pluck(:place_id) if params.key?(:venue) && params[:venue].present?

        if params[:area].present?
          any_of do
            with :place_id, Area.where(id: params[:area]).joins(:places).where(places: { is_location: false }).pluck('places.id').uniq + [0]
            with :location, Area.where(id: params[:area]).map { |a| a.locations.map(&:id) }.flatten + [0]
          end
        end

        if params[:start_date].present? && params[:end_date].present?
          params[:start_date] = Array(params[:start_date])
          params[:end_date] = Array(params[:end_date])
          any_of do
            params[:start_date].each_with_index do |start, index|
              d1 = Timeliness.parse(start, zone: :current).beginning_of_day
              d2 = Timeliness.parse(params[:end_date][index], zone: :current).end_of_day
              with :activity_date, d1..d2
            end
          end
        elsif params[:start_date].present?
          d = Timeliness.parse(params[:start_date][0], zone: :current)
          with :activity_date, d
        end

        any_of do
           all_of do
             with :activitable_type, 'Event'
             with :events_active, true
           end
           with :activitable_type, 'Venue'
        end

        order_by(params[:sorting] || :activity_date, params[:sorting_dir] || :asc)
        paginate page: (params[:page] || 1), per_page: (params[:per_page] || 30)
      end
    end
  end

  def self.in_areas(areas)
    subquery = Place.connection.unprepared_statement { Place.in_areas(areas).to_sql }
    joins("INNER JOIN (#{subquery}) areas_places ON areas_places.id=events.place_id")
  end

  def self.in_places(places)
    places_list = Place.where(id: places)
    where(
      'events.place_id in (?) or events.place_id in (
          select place_id FROM locations_places where location_id in (?)
      )',
      places_list.map(&:id).uniq + [0],
      places_list.select(&:is_location?).map(&:location_id).compact.uniq + [0])
  end

  private

  # Sets the default date (today), user and campaign for new records
  def set_default_values
    return unless new_record?
    self.activity_date ||= Date.today
    self.company_user_id ||= User.current.current_company_user.id if User.current.present?
    self.campaign = activitable.campaign if activitable.is_a?(Event)
  end

  def delegate_campaign_id_from_event
    return true unless activitable.is_a?(Event)
    self.campaign = activitable.campaign
    self.campaign_id = activitable.campaign_id
  end
end
