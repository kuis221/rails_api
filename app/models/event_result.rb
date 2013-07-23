# == Schema Information
#
# Table name: event_results
#
#  id              :integer          not null, primary key
#  form_field_id   :integer
#  event_id        :integer
#  kpis_segment_id :integer
#  value           :text
#  scalar_value    :decimal(10, 2)   default(0.0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class EventResult < ActiveRecord::Base
	belongs_to :event
	belongs_to :kpis_segment
	belongs_to :form_field, class_name: 'CampaignFormField'

  attr_accessible :form_field_id, :kpis_segment_id, :value

  before_save :set_scalar_value


  private
    def set_scalar_value
      if form_field.is_numeric?
         self.scalar_value = value.to_f  rescue 0.0
      end
    end
end
