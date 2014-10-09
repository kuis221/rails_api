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
#

require 'rails_helper'

describe FormField, type: :model do
  it { is_expected.to belong_to(:fieldable) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:type) }
  it { is_expected.to validate_presence_of(:ordering) }
  it { is_expected.to validate_numericality_of(:ordering) }

  describe 'settings' do
    it { is_expected.to allow_value('range_format' => 'digits').for(:settings) }
    it { is_expected.to allow_value('range_format' => 'words').for(:settings) }
    it { is_expected.to allow_value('range_format' => 'characters').for(:settings) }
    it { is_expected.to allow_value('range_format' => 'value').for(:settings) }
    it { is_expected.not_to allow_value('range_format' => 'strange').for(:settings) }

    it { is_expected.to allow_value('range_min' => '100', 'range_max' => '200').for(:settings) }
    it { is_expected.to allow_value('range_min' => '', 'range_max' => '200').for(:settings) }
    it { is_expected.to allow_value('range_min' => '100', 'range_max' => '').for(:settings) }
    it { is_expected.to allow_value('range_min' => nil, 'range_max' => nil).for(:settings) }
    it { is_expected.to allow_value('range_min' => '100', 'range_max' => '100').for(:settings) }
    it { is_expected.not_to allow_value('range_min' => '100', 'range_max' => '1').for(:settings) }
    it { is_expected.not_to allow_value('range_min' => 'xx', 'range_max' => '').for(:settings) }
    it { is_expected.not_to allow_value('range_min' => '', 'range_max' => 'xx').for(:settings) }
  end

  let(:field) { FormField.new }
  describe '#field_options' do
    it 'should return basic options' do
      expect(field.field_options(FormFieldResult.new)).to eql(as: :string)
    end
  end

  describe '#field_classes' do
    it 'should return generic class' do
      expect(field.field_classes).to eql(['input-xlarge'])
    end
  end

  describe '#store_value' do
    it 'should return the values as is' do
      expect(field.store_value(1)).to eql 1
      expect(field.store_value('two')).to eql 'two'
      expect(field.store_value(1.2)).to eql 1.2
    end
  end

  describe '#options_for_input' do
    let(:campaign) { create(:campaign) }
    it 'should return the kpis segments for a KPI form field' do
      kpi =  create(:kpi, name: 'My Custom KPI',
        description: 'my custom kpi description',
        kpi_type: 'count', capture_mechanism: 'dropdown', company: campaign.company,
        kpis_segments: [
          segment1 = create(:kpis_segment, text: 'Option1'),
          segment2 = create(:kpis_segment, text: 'Option2')])

      field = campaign.add_kpi(kpi)

      expect(field.options_for_input).to eql [['Option1', segment1.id], ['Option2', segment2.id]]
    end

    it 'should NOT return the kpis segments that were excluded' do
      kpi =  create(:kpi, name: 'My Custom KPI',
        description: 'my custom kpi description',
        kpi_type: 'count', capture_mechanism: 'dropdown', company: campaign.company,
        kpis_segments: [
          segment1 = create(:kpis_segment, text: 'Option1'),
          segment2 = create(:kpis_segment, text: 'Option2')])

      field = campaign.add_kpi(kpi)
      field.settings ||= {}
      field.settings['disabled_segments'] = [segment1.id.to_s]

      expect(field.options_for_input).to eql [['Option2', segment2.id]]
    end

    it 'should return the kpis segments that were excluded if include_excluded is true' do
      kpi =  create(:kpi, name: 'My Custom KPI',
        description: 'my custom kpi description',
        kpi_type: 'count', capture_mechanism: 'dropdown', company: campaign.company,
        kpis_segments: [
          segment1 = create(:kpis_segment, text: 'Option1'),
          segment2 = create(:kpis_segment, text: 'Option2')])

      field = campaign.add_kpi(kpi)
      field.settings ||= {}
      field.settings['disabled_segments'] = [segment1.id.to_s]

      expect(field.options_for_input(true)).to eql [['Option1', segment1.id], ['Option2', segment2.id]]
    end

    it 'should return the form field options' do
      field = create(:form_field, type: 'FormField::Dropdown',
        fieldable: campaign, kpi_id: nil,
        options: [
          option1 = create(:form_field_option, name: 'Option1'),
          option2 = create(:form_field_option, name: 'Option2')])

      expect(field.options_for_input).to eql [['Option1', option1.id], ['Option2', option2.id]]
    end
  end

  describe '#format_html' do
    it 'should return the values as is' do
      expect(field.format_html(build(:form_field_result, value: nil, form_field: field))).to eql nil
      expect(field.format_html(build(:form_field_result, value: 1, form_field: field))).to eql 1
      expect(field.format_html(build(:form_field_result, value: 'two', form_field: field))).to eql 'two'
      expect(field.format_html(build(:form_field_result, value: 1.2, form_field: field))).to eql 1.2
    end
  end
end
