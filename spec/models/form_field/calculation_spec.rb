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

describe FormField::Calculation, type: :model do
  describe '#format_json' do
    let(:event) { create(:event) }
    let(:field) do
      create(:form_field_calculation,
             fieldable: event.campaign,
             options: [build(:form_field_option, name: 'Option 1'),
                       build(:form_field_option, name: 'Option 1')])
    end

    describe 'without values' do
      let(:result) { create(:form_field_result, form_field: field, resultable: event) }
      let(:json) { field.format_json(result) }

      it 'returns the correct values' do
        expect(json[:value]).to eql nil
        expect(json[:segments].map { |s| s[:value] }).to eql [nil, nil]
      end
    end

    describe 'with values' do
      let(:result) do
        create(:form_field_result,
               value: { field.options[0].id.to_s => 10, field.options[1].id.to_s => 20.5 },
               form_field: field, resultable: event)
      end
      let(:json) { field.format_json(result) }

      it 'returns the correct values' do
        expect(json[:value]).to eql 30.5
        expect(json[:segments].map { |s| s[:value] }).to eql [10, 20.5]
      end

      it 'calculates the correct total for multiply operations' do
        field.update_attributes(operation: '*')
        expect(json[:value]).to eql 205.0
        expect(json[:segments].map { |s| s[:value] }).to eql [10, 20.5]
      end

      it 'calculates the correct total for subtract operations' do
        field.update_attributes(operation: '-')
        expect(json[:value]).to eql(-10.5)
        expect(json[:segments].map { |s| s[:value] }).to eql [10, 20.5]
      end

      it 'calculates the correct total for divide operations' do
        field.update_attributes(operation: '/')
        expect(json[:value]).to eql 0.4878048780487805
        expect(json[:segments].map { |s| s[:value] }).to eql [10, 20.5]
      end
    end
  end
end
