# == Schema Information
#
# Table name: form_fields
#
#  id             :integer          not null, primary key
#  fieldable_id   :integer
#  fieldable_type :string(255)
#  name           :string(255)
#  type           :string(255)
#  settings       :text
#  ordering       :integer
#  required       :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  kpi_id         :integer
#  multiple       :boolean
#

require 'rails_helper'
describe FormField::Percentage, type: :model do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign) }

  before { Company.current = company }

  describe '#field_options' do
    it 'should return only valid values ' do
      field = create(:form_field_percentage, name: 'Gender',
        fieldable: campaign, options: [
          option1 = create(:form_field_option, name: 'Male', ordering: 1),
          option2 = create(:form_field_option, name: 'Female', ordering: 2)])

      event1 = create(:approved_event, campaign: campaign)
      event2 = create(:approved_event, campaign: campaign)
      event3 = create(:approved_event, campaign: campaign)
      event4 = create(:approved_event, campaign: campaign)
      event5 = create(:approved_event, campaign: campaign)
      event6 = create(:approved_event, campaign: campaign)

      event1.results_for([field]).first.value = {}
      event1.save
      event2.results_for([field]).first.value = { option1.id.to_s => 100, option2.id.to_s => 0 }
      event2.save
      event3.results_for([field]).first.value = { option1.id.to_s => 50, option2.id.to_s => 50 }
      event3.save
      event4.results_for([field]).first.value = { option1.id.to_s => 80, option2.id.to_s => 20 }
      event4.save
      event5.results_for([field]).first.value = { option1.id.to_s => 40, option2.id.to_s => 60 }
      event5.save
      event6.results_for([field]).first.value = { option1.id.to_s => 0, option2.id.to_s => 100 }
      event6.save

      events = field.form_field_results.for_event_campaign(campaign)
      result = events.map(&:hash_value).compact

      expect(result).to eq([{}, { option1.id.to_s => '100', option2.id.to_s => '0' }, { option1.id.to_s => '50', option2.id.to_s => '50' },
                            { option1.id.to_s => '80', option2.id.to_s => '20' }, { option1.id.to_s => '40', option2.id.to_s => '60' },
                            { option1.id.to_s => '0', option2.id.to_s => '100' }])

      values =  field.results_for_percentage_chart_for_hash(result).sort
      expect(values).to eq([['Female', 230.0], ['Male', 270.0]])
    end
  end
end