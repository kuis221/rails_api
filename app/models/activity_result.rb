# == Schema Information
#
# Table name: activity_results
#
#  id            :integer          not null, primary key
#  activity_id   :integer
#  form_field_id :integer
#  value         :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class ActivityResult < ActiveRecord::Base
  belongs_to :activity
  belongs_to :form_field

  validate :valid_value?
  validates :form_field_id, numericality: true, presence: true

  before_save :prepare_for_store

  def value
    if form_field.settings.present? && form_field.settings.has_key?('multiple') && form_field.settings['multiple']
      self.attributes['value'].try(:split, ',')
    else
      self.attributes['value']
    end
  end
  
  def to_html
    form_field.format_html
  end

  private
    def valid_value?
      return if form_field.nil?
      if form_field.required? && (value.nil? || (value.is_a?(String) && value.empty?))
        errors.add(:value, I18n.translate('errors.messages.blank'))
      end
    end

    def prepare_for_store
      self.value = form_field.store_value(value)
      true
    end
end
