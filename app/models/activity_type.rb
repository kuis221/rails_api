# == Schema Information
#
# Table name: activity_types
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  active      :boolean          default(TRUE)
#  company_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class ActivityType < ActiveRecord::Base
  belongs_to :company
  has_many :form_fields, :as => :fieldable, order: 'form_fields.ordering ASC'

  validates :name, presence: true
  validates :company_id, presence: true, numericality: true
end
