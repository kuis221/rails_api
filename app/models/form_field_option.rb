# == Schema Information
#
# Table name: form_field_options
#
#  id            :integer          not null, primary key
#  form_field_id :integer
#  name          :string(255)
#  ordering      :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class FormFieldOption < ActiveRecord::Base
  belongs_to :form_field

  validates :form_field_id, numericality: true, presence: true
  validates :name, presence: true
  validates :ordering, presence: true, numericality: true
end
