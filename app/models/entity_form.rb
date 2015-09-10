# == Schema Information
#
# Table name: entity_forms
#
#  id         :integer          not null, primary key
#  entity     :string(255)
#  entity_id  :integer
#  company_id :integer
#  created_at :datetime
#  updated_at :datetime
#

class EntityForm < ActiveRecord::Base
  belongs_to :company

  has_many :form_fields, -> { order('form_fields.ordering ASC') }, as: :fieldable
  scoped_to_company

  validates :entity, presence: true, uniqueness: { scope: :company_id }
  scope :for_entity, ->(entity) { where(entity: entity) }
end
