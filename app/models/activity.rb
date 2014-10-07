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

  validates :campaign_id, presence: true, numericality: true,
                          if: -> (_activitable) { activitable_type == 'Event' }
  validates :activitable_id, presence: true, numericality: true
  validates :activitable_type, presence: true
  validates :company_user_id, presence: true, numericality: true
  validates :activity_date, presence: true

  scope :active, -> { where(active: true) }

  scope :accessible_by_user, -> { self }

  after_initialize :set_default_values

  delegate :company_id, :company, :place, to: :activitable, allow_nil: true
  delegate :td_linx_code, :name, :city, :state, :zipcode, :street_number, :route,
           to: :place, allow_nil: true, prefix: true

  delegate :name, to: :campaign, allow_nil: true, prefix: true

  accepts_nested_attributes_for :results, allow_destroy: true

  before_validation :delegate_campaign_id_from_event

  searchable do
    integer :company_id
    integer :campaign_id
    integer :activity_type_id
    integer :company_user_id
    string :activitable do
      "#{activitable_type}#{activitable_id}"
    end
    date :activity_date
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def results_for_type
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

  def valid_activity_type_ids
    if campaign.present?
      campaign.activity_type_ids
    elsif company.present?
      company.activity_type_ids
    else
      []
    end
  end

  class << self
    def do_search(params)
      solr_search do
        with :company_id, params[:company_id]
        with :campaign_id, params[:campaign] if params.key?(:campaign) && params[:campaign].present?
        with :activity_type_id, params[:activity_type] if params.key?(:activity_type) && params[:activity_type].present?

        if params[:start_date].present? && params[:end_date].present?
          d1 = Timeliness.parse(params[:start_date], zone: :current).beginning_of_day
          d2 = Timeliness.parse(params[:end_date], zone: :current).end_of_day
          with :activity_date, d1..d2
        elsif params[:start_date].present?
          d = Timeliness.parse(params[:start_date], zone: :current)
          with :activity_date, d
        end

        order_by(params[:sorting] || :activity_date, params[:sorting_dir] || :desc)
        paginate page: (params[:page] || 1), per_page: (params[:per_page] || 30)
      end
    end
  end

  private

  # Sets the default date (today) and user for new records
  def set_default_values
    return unless new_record?
    self.activity_date ||= Date.today
    self.company_user_id ||= User.current.current_company_user.id if User.current.present?
    self.campaign = activitable.campaign if activitable.is_a?(Event)
  end

  def delegate_campaign_id_from_event
    return unless activitable.is_a?(Event)
    self.campaign = activitable.campaign
    self.campaign_id = activitable.campaign_id
  end
end
