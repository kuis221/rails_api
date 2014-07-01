# == Schema Information
#
# Table name: form_field_results
#
#  id              :integer          not null, primary key
#  activity_id     :integer
#  form_field_id   :integer
#  value           :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  hash_value      :hstore
#  scalar_value    :decimal(10, 2)   default(0.0)
#  resultable_id   :integer
#  resultable_type :string(255)
#

class FormFieldResult < ActiveRecord::Base
  belongs_to :resultable, polymorphic: true
  belongs_to :form_field

  validate :valid_value?
  validates :form_field_id, numericality: true, presence: true

  has_one :attached_asset, :as => :attachable, dependent: :destroy

  serialize :hash_value, ActiveRecord::Coders::Hstore

  before_validation :prepare_for_store

  scope :for_kpi, -> (kpi){ joins(:form_field).where(form_fields: {kpi_id: kpi}) }

  scope :for_event_campaign, -> (campaign){ joins('INNER JOIN events ON events.id=form_field_results.resultable_id AND form_field_results.resultable_type=\'Event\'').where(events: {campaign_id: campaign}) }

  scope :for_place_in_company, -> (place, company){ joins('INNER JOIN events ON events.id=form_field_results.resultable_id AND form_field_results.resultable_type=\'Event\'').where(events: {company_id: company, place_id: place}) }

  def value
    if form_field.present? && form_field.is_hashed_value?
      if form_field.type == 'FormField::Checkbox'
        (self.attributes['hash_value'].try(:keys) || []).map(&:to_i)
      else
        self.attributes['hash_value']
      end
    elsif form_field.present? && form_field.settings.present? && form_field.settings.has_key?('multiple') && form_field.settings['multiple']
      self.attributes['value'].try(:split, ',')
    else
      self.attributes['value']
    end
  end

  def to_html
    form_field.format_html self
  end

  protected
    def valid_value?
      return if form_field.nil?
      form_field.validate_result(self)
    end

    def prepare_for_store
      unless form_field.nil?
        self.value = form_field.store_value(self.attributes['value'])
        if form_field.is_hashed_value?
          (self.hash_value, self.value) = [self.attributes['value'], nil]
        elsif form_field.is_attachable?
          self.build_attached_asset(direct_upload_url: self.value) unless self.value.nil? || self.value == ''
        end
      end
      self.scalar_value = self.value.to_f rescue 0 if self.value.present? && self.value.to_s =~ /\A[0-9\.\,]+\z/
      true
    end
end
