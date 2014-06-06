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

  has_many :results, class_name: 'ActivityResult', inverse_of: :activity

  validates :activity_type_id, numericality: true, presence: true,
    :inclusion => { :in => proc { |activity| activity.campaign.present? ? activity.campaign.activity_type_ids : (activity.company.present? ? activity.company.activity_type_ids : []) } }

  validates :campaign_id, presence: true, numericality: true,
    if: -> (activitable) { activitable_type == 'Event' }
  validates :activitable_id, presence: true, numericality: true
  validates :activitable_type, presence: true
  validates :company_user_id, presence: true, numericality: true
  validates :activity_date, presence: true
  validates_datetime :activity_date, allow_nil: false, allow_blank: false

  scope :active, -> { where(active: true) }

  scope :with_results_for, ->(fields) {
    select('DISTINCT activities.*').
    joins(:results).
    where(activity_results: {form_field_id: fields}).
    where('activity_results.value is not NULL AND activity_results.value !=\'\'') }

  after_initialize :set_default_values

  delegate :company_id, :company, to: :activitable, allow_nil: true

  accepts_nested_attributes_for :results, allow_destroy: true

  before_validation :delegate_campaign_id_from_event

  after_commit :reindex_trending

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def all_values_for_trending(term=nil)
    scope = results.joins(:form_field).
      where(form_fields: {type: ActivityType::TRENDING_FIELDS_TYPES}).
      where('activity_results.value is not NULL AND activity_results.value !=\'\'')
    scope = scope.where('lower(value) like ?', "%#{term}%") if term.present?
    scope.pluck('activity_results.value')
  end

  def results_for_type
    activity_type.form_fields.map do |field|
      result = results.detect{|r| r.form_field_id == field.id} ||
               results.build({form_field_id: field.id}, without_protection: true)
      result.form_field = field
      result
    end
  end

  def results_for(fields)
    fields.map do |field|
      result = results.select{|r| r.form_field_id == field.id}.first ||
               results.build({form_field_id: field.id}, without_protection: true)
      result.form_field = field
      result
    end
  end

  def photos
    scope = results.joins(:form_field).
      where(form_fields: {type: ActivityType::PHOTO_FIELDS_TYPES}).
      where('activity_results.value is not NULL AND activity_results.value !=\'\'').
      preload(:attached_asset).map(&:attached_asset)
  end

  private
    # Sets the default date (today) and user for new records
    def set_default_values
      if new_record?
        self.activity_date ||= Date.today
        self.company_user_id ||= User.current.current_company_user.id if User.current.present?
        self.campaign = activitable.campaign if activitable.is_a?(Event)
      end
    end

    def delegate_campaign_id_from_event
      if activitable.is_a?(Event)
        self.campaign = activitable.campaign
        self.campaign_id = activitable.campaign_id
      end
    end

    def reindex_trending
      if all_values_for_trending.count > 0
        Sunspot.index TrendObject.new(self)
      else
        Sunspot.remove TrendObject.new(self)
      end
    end
end
