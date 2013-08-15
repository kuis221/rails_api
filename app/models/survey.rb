# == Schema Information
#
# Table name: surveys
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Survey < ActiveRecord::Base
  belongs_to :event
  attr_accessible :surveys_answers_attributes

  has_many :surveys_answers, autosave: true

  accepts_nested_attributes_for :surveys_answers

  def brands
    field = event.campaign.form_fields.scoped_by_kpi_id(Kpi.surveys).first
    if field.present?
      Brand.where(id: field.options['brands'])
    end
  end

  def answer_for(question_id, brand_id)
    surveys_answers.select{|a| a.question_id == question_id && a.brand_id == brand_id}.first || surveys_answers.build({question_id: question_id, brand_id: brand_id}, without_protection: true)
  end
end
