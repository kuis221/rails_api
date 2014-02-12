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

  private
    def valid_value?
      return if form_field.nil?
      if form_field.required == true && (value.nil? || (value.is_a?(String) && value.empty?))
        errors.add(:value, I18n.translate('errors.messages.blank'))
      end
    end
end
