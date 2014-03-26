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
#  hash_value    :hstore
#  scalar_value  :decimal(10, 2)   default(0.0)
#

class ActivityResult < ActiveRecord::Base
  belongs_to :activity
  belongs_to :form_field

  validate :valid_value?
  validates :form_field_id, numericality: true, presence: true

  serialize :hash_value, ActiveRecord::Coders::Hstore

  before_validation :prepare_for_store

  def value
    if form_field.present? && form_field.is_hashed_value?
      self.attributes['hash_value']
    elsif form_field.present? && form_field.settings.present? && form_field.settings.has_key?('multiple') && form_field.settings['multiple']
      self.attributes['value'].try(:split, ',')
    else
      self.attributes['value']
    end
  end

  def to_html
    form_field.format_html self
  end

  private
    def valid_value?
      return if form_field.nil?
      if form_field.required? && (value.nil? || (value.is_a?(String) && value.empty?))
        errors.add(:value, I18n.translate('errors.messages.blank'))
      end
    end

    def prepare_for_store
      unless form_field.nil?
        self.value = form_field.store_value(self.attributes['value'])
        if form_field.is_hashed_value?
          (self.hash_value, self.value) = [self.attributes['value'], nil]
        end
      end
      self.scalar_value = self.value.to_f rescue 0 if self.value.present? && self.value =~ /\A[0-9\.\,]+\z/
      true
    end
end
