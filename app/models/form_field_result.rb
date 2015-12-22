# == Schema Information
#
# Table name: form_field_results
#
#  id              :integer          not null, primary key
#  form_field_id   :integer
#  value           :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  hash_value      :hstore
#  scalar_value    :decimal(15, 2)   default("0")
#  resultable_id   :integer
#  resultable_type :string(255)
#

class FormFieldResult < ActiveRecord::Base
  attr_accessor :value_dirty, :value_tmp

  belongs_to :resultable, polymorphic: true
  belongs_to :form_field

  validate :valid_value?
  validates :form_field_id, numericality: true, presence: true

  delegate :company_id, to: :resultable

  has_one :attached_asset, as: :attachable, dependent: :destroy, inverse_of: :attachable

  before_validation :check_value_dirty
  after_commit :reindex_trending

  scope :for_kpi, -> (kpi) { joins(:form_field).where(form_fields: { kpi_id: kpi }) }

  scope :for_event_campaign, -> (campaign) { joins('INNER JOIN events ON events.id=form_field_results.resultable_id AND form_field_results.resultable_type=\'Event\'').where(events: { campaign_id: campaign }) }

  scope :for_place_in_company, -> (place, company) { joins('INNER JOIN events ON events.id=form_field_results.resultable_id AND form_field_results.resultable_type=\'Event\'').where(events: { company_id: company, place_id: place }) }

  def value
    return @value_tmp if @value_dirty
    form_field.result_value self if form_field.present?
  end

  def value=(val)
    unless form_field.present?
      @value_dirty = true
      return @value_tmp = val
    end
    val = form_field.store_value(val)
    if form_field.is_hashed_value?
      self[:hash_value] = val
    else
      if form_field.is_attachable? && !val.blank?
        build_attached_asset(direct_upload_url: val)
      end
      self[:scalar_value] = val.to_f rescue 0 if val.present? && val.to_s =~ /\A[0-9\.\,]+\z/
      self[:value] = val
    end
  end

  def form_field_id=(id)
    super
    check_value_dirty
  end

  def form_field=(field)
    super
    check_value_dirty
  end

  def to_html
    form_field.format_html self
  end

  def to_csv
    form_field.format_csv self
  end

  def to_chart_data
    form_field.format_chart_data self
  end

  def to_text
    form_field.format_text self
  end

  protected

  def valid_value?
    return if form_field.nil?
    form_field.validate_result(self)
  end

  def check_value_dirty
    return unless @value_dirty && form_field.present?
    self.value = @value_tmp # re-assign the value now that there is a a form field
    @value_dirty = @value_tmp = nil
  end

  def reindex_trending
    return unless form_field.trendeable?
    Sunspot.index(TrendObject.new(resultable, self))
  end
end
