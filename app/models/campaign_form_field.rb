# == Schema Information
#
# Table name: campaign_form_fields
#
#  id          :integer          not null, primary key
#  campaign_id :integer
#  kpi_id      :integer
#  ordering    :integer
#  name        :string(255)
#  field_type  :string(255)
#  options     :text
#  section_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class CampaignFormField < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :kpi

  serialize :options

  TRENDING_FIELDS_TYPES = ['text', 'textarea']

  validates :campaign_id, numericality: true, allow_nil: true
  validates :kpi_id,      numericality: true, allow_nil: true
  validates :section_id,  numericality: true, allow_nil: true
  validates :ordering,    numericality: true, presence: true

  delegate :name, :module, to: :kpi, allow_nil: true, prefix: true

  scope :for_event_data, lambda{ joins('LEFT JOIN kpis ON campaign_form_fields.kpi_id=kpis.id').where("campaign_form_fields.kpi_id is null or kpis.module in (?)", ['custom', 'consumer_reach', 'demographics']) }

  scope :for_trends, -> { where(field_type: TRENDING_FIELDS_TYPES ) }

  # For field - sections relationship
  has_many :fields, class_name: 'CampaignFormField', foreign_key: :section_id, order: 'ordering ASC', dependent: :destroy
  accepts_nested_attributes_for :fields

  def field_options(result)
    options = {as: simple_form_field_type, capture_mechanism: self.capture_mechanism, label: self.name, field_id: self.id, options: self.options, required: is_required?, input_html: {value: result.value, class: field_validation_classes(result), required: (is_required? ? 'required' : nil )}}
    unless result.kpis_segment_id.nil?
      options.merge!(label: result.kpis_segment.text)
      options[:input_html].merge!('data-segment-field-id' => self.id)
    end
    if field_type == 'count'
      options.merge!(collection: kpi.kpis_segments.map{|s| [s.text, s.id]})
    end
    options
  end

  def capture_mechanism
    options.try(:[], :capture_mechanism)
  end

  def simple_form_field_type
    case field_type
    when 'text', 'number'
      :string
    when 'percentage'
      :percentage
    when 'textarea'
      :text
    when 'count'
      case self.capture_mechanism
      when 'radio' then :radio_buttons
      when 'checkbox' then :check_boxes
      else :select
      end
    else
      field_type.to_s
    end
  end

  # TODO: should we delegate this to the kpi?
  def is_segmented?
    ['percentage'].include? field_type
  end

  def is_section?
    'section' == field_type
  end

  def is_required?
    required = options.try(:[], :required)
    required == 'true' || required == true
  end

  def is_numeric?
    ['number', 'percentage', 'count'].include?(field_type)
  end

  def is_decimal?
    (['number', 'percentage'].include?(field_type) && ['decimal', 'currency'].include?(capture_mechanism))
  end

  def field_validation_classes(result)
    validation_classes = []
    validation_classes.push 'integer' if is_numeric? && !is_decimal?
    validation_classes.push 'decimal' if is_decimal?
    validation_classes.push 'segment-field' unless result.kpis_segment_id.nil?
    validation_classes.join ' '
  end
end
