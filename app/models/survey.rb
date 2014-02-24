# == Schema Information
#
# Table name: surveys
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  created_by_id :integer
#  updated_by_id :integer
#  active        :boolean          default(TRUE)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Survey < ActiveRecord::Base
  belongs_to :event

  has_many :surveys_answers, autosave: true, inverse_of: :survey

  accepts_nested_attributes_for :surveys_answers

  delegate :company_id, to: :event

  after_save :reindex_event

  def brands
    event.campaign.survey_brands
  end

  def age
    answer = surveys_answers.select{|a| a.kpi_id == Kpi.age.id }.first
    answer.segment.text unless answer.nil? || answer.segment.nil?
  end

  def gender
    answer = surveys_answers.select{|a| a.kpi_id == Kpi.gender.id }.first
    answer.segment.text unless answer.nil? || answer.segment.nil?
  end

  def ethnicity
    answer = surveys_answers.select{|a| a.kpi_id == Kpi.ethnicity.id }.first
    answer.segment.text unless answer.nil? || answer.segment.nil?
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def answer_for(question_id, brand_id, kpi_id=nil)
    if kpi_id.nil?
      surveys_answers.select{|a| a.question_id == question_id && a.brand_id == brand_id}.first || surveys_answers.build({question_id: question_id, brand_id: brand_id}, without_protection: true)
    else
      surveys_answers.select{|a| a.question_id == question_id && a.kpi_id == kpi_id}.first || surveys_answers.build({question_id: question_id, kpi_id: kpi_id}, without_protection: true)
    end
  end

  protected

    def reindex_event
      # if this is the first survey for the event, then reindex it to set the flag "has_surveys" true
      if event.present? && event.surveys.count == 1
        Sunspot.index event
      end
    end
end
