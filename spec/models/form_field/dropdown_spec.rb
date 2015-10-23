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
describe FormField::Dropdown, type: :model do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign) }

  before { Company.current = company }

  describe '#field_options' do
    it 'should return only valid values ' do
      field = create(:form_field_dropdown, name: 'My Ddown Field',
        fieldable: campaign, options: [
          option1 = create(:form_field_option, name: 'Ddwon Opt1'),
          option2 = create(:form_field_option, name: 'Ddwon Opt2'),
          option3 = create(:form_field_option, name: 'Ddwon Opt3'),
          option4 = create(:form_field_option, name: 'Ddwon Opt4')])

      event1 = create(:approved_event, campaign: campaign)
      event2 = create(:approved_event, campaign: campaign)
      event3 = create(:approved_event, campaign: campaign)
      event4 = create(:approved_event, campaign: campaign)
      event5 = create(:approved_event, campaign: campaign)
      event6 = create(:approved_event, campaign: campaign)

      event1.results_for([field]).first.value = option1.id
      event1.save
      event2.results_for([field]).first.value = option2.id
      event2.save
      event3.results_for([field]).first.value = option3.id
      event3.save
      event4.results_for([field]).first.value = ''
      event4.save
      event5.results_for([field]).first.value = option3.id
      event5.save
      event6.results_for([field]).first.value = option4.id
      event6.save

      FormFieldOption.destroy(option4)

      result = field.form_field_results.for_event_campaign(campaign).group(:value).count

      expect(result[option1.id.to_s]).to eq(1)
      expect(result[option2.id.to_s]).to eq(1)
      expect(result[option3.id.to_s]).to eq(2)
      expect(result[option4.id.to_s]).to eq(1)
      expect(result['']).to eq(1)

      values =  field.results_for_percentage_chart_for_value(result).sort

      expect(values).to eq([['Ddwon Opt1', 1], ['Ddwon Opt2', 1], ['Ddwon Opt3', 2]])
    end
  end
end