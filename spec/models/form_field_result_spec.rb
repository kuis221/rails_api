# == Schema Information
#
# Table name: form_field_results
#
#  id              :integer          not null, primary key
#  form_field_id   :integer
#  value           :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  hash_value      :hstore
#  scalar_value    :decimal(15, 2)   default(0.0)
#  resultable_id   :integer
#  resultable_type :string(255)
#

require 'rails_helper'

describe FormFieldResult, type: :model do
  it { is_expected.to belong_to(:resultable) }
  it { is_expected.to belong_to(:form_field) }

  it { is_expected.to validate_presence_of(:form_field_id) }
  it { is_expected.to validate_numericality_of(:form_field_id) }

  describe 'for required fields' do
    before { subject.form_field = build(:form_field, type: 'FormField::Number', required: true) }
    it { is_expected.not_to allow_value(nil).for(:value) }
    it { is_expected.not_to allow_value('').for(:value) }
    it { is_expected.to allow_value('1').for(:value) }
    it { is_expected.to allow_value(1).for(:value) }
  end

  describe 'for non required fields' do
    before { subject.form_field = build(:form_field, type: 'FormField::Number', required: false) }
    it { is_expected.to allow_value(nil).for(:value) }
    it { is_expected.to allow_value('').for(:value) }
    it { is_expected.to allow_value('1').for(:value) }
    it { is_expected.to allow_value(1).for(:value) }
  end

  describe 'value=' do
    let(:result) { build(:form_field_result, form_field: form_field) }

    context 'with form_field present' do
      let(:form_field) { build(:form_field_text) }

      it 'assigns a value inmediately' do
        result.value = '3'
        expect(result['value']).to eql '3'
      end
    end

    context 'without a form_field present' do
      let(:form_field) { nil }

      it 'does not assigns the value' do
        result.value = '3'
        expect(result['value']).to be_nil
      end

      it 'stores the value in value_tmp' do
        result.value = '3'
        expect(result.value_tmp).to eql '3'
      end

      it 'returns the correct value' do
        result.value = '3'
        expect(result.value).to eql '3'
      end

      it 'sets the correct value when a form field is assigned' do
        result.value = '3'
        expect(result['value']).to be_nil
        result.form_field = create(:form_field_text, fieldable: create(:campaign))
        expect(result['value']).to eq '3'
        expect(result.value_tmp).to be_nil
      end
    end

    context 'mass attribute assignment' do
      let(:form_field) { create(:form_field_text, fieldable: create(:campaign)) }
      it 'correctly assigns the value' do
        result = FormFieldResult.new(value: 'xxx', form_field_id: form_field.id)
        expect(result['value']).to eql 'xxx'
      end
    end
  end

  describe 'validations' do
    before { subject.form_field = form_field }

    describe 'for numeric fields' do
      let(:form_field) do
        build(:form_field_number,
               settings: {},
               fieldable: create(:activity_type, company_id: 1),
               required: false)
      end

      describe "when doesn't have range validation rules" do
        it { is_expected.to validate_numericality_of(:value) }
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.to allow_value('1').for(:value) }
        it { is_expected.to allow_value(1).for(:value) }
      end

      describe 'when range format is digits' do
        before do
          form_field.settings = {
            'range_format' => 'digits', 'range_min' => '2', 'range_max' => '4' }
        end
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.not_to allow_value('1').for(:value).with_message('is invalid') }
        it { is_expected.to allow_value(1234).for(:value) }
        it { is_expected.to allow_value('1234').for(:value) }
        it { is_expected.to allow_value('1.234').for(:value) }
        it { is_expected.to allow_value(1.234).for(:value) }
        it { is_expected.not_to allow_value('12345').for(:value).with_message('is invalid') }
      end

      describe 'when range format is value' do
        before do
          form_field.settings = {
            'range_format' => 'value', 'range_min' => '2', 'range_max' => '4' }
        end
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.to allow_value(2).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value(3).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value(4).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value(4.0).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value('4').for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value(1).for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value(5).for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value('4.1').for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value(4.1).for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value('5').for(:value).with_message('is invalid') }
      end

      describe 'when only have a min but not a max' do
        before do
          form_field.settings = {
            'range_format' => 'value', 'range_min' => '2', 'range_max' => '' }
        end
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.to allow_value(2).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value(3).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value(500).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value(4.0).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value('4').for(:value).with_message('is invalid') }
        it { is_expected.to allow_value('5000').for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value(1).for(:value).with_message('is invalid') }
      end

      describe 'when only have a max but not a min' do
        before do
          form_field.settings = {
           'range_format' => 'value', 'range_min' => '', 'range_max' => '4' }
        end
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.to allow_value(-2).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value(0).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value(3).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value(4.0).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value('4').for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value(500).for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value('5000').for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value(4.1).for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value(10).for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value('10').for(:value).with_message('is invalid') }
      end
    end

    describe 'for currency fields' do
      describe "when doesn't have range validation rules" do
        let(:form_field) do
          create(:form_field_currency,
                 settings: {},
                 fieldable: create(:activity_type, company_id: 1),
                 required: false)
        end
        it { is_expected.to validate_numericality_of(:value) }
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.to allow_value('1').for(:value) }
        it { is_expected.to allow_value(1).for(:value) }
      end

      describe 'when range format is digits' do
        let(:form_field) do
          create(:form_field_currency,
                 settings: { 'range_format' => 'digits', 'range_min' => '2', 'range_max' => '4' },
                 fieldable: create(:activity_type, company_id: 1),
                 required: false)
        end
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.not_to allow_value('1').for(:value).with_message('is invalid') }
        it { is_expected.to allow_value(1234).for(:value) }
        it { is_expected.to allow_value('1234').for(:value) }
        it { is_expected.to allow_value('1.234').for(:value) }
        it { is_expected.to allow_value(1.234).for(:value) }
        it { is_expected.not_to allow_value('12345').for(:value).with_message('is invalid') }
      end

      describe 'when range format is value' do
        let(:form_field) do
          create(:form_field,
                 type: 'FormField::Currency',
                 settings: { 'range_format' => 'value', 'range_min' => '2', 'range_max' => '4' },
                 fieldable: create(:activity_type, company_id: 1),
                 required: false)
        end
        before { subject.form_field_id = form_field.id }
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.to allow_value(2).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value(3).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value(4).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value(4.0).for(:value).with_message('is invalid') }
        it { is_expected.to allow_value('4').for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value(1).for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value(5).for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value('4.1').for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value(4.1).for(:value).with_message('is invalid') }
        it { is_expected.not_to allow_value('5').for(:value).with_message('is invalid') }
      end
    end

    describe 'for photo fields' do
      let(:form_field) do
        create(:form_field_photo,
               fieldable: create(:activity_type, company_id: 1),
               required: false)
      end
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.not_to allow_value('sdfsd').for(:value).with_message('is not valid') }
      it { is_expected.not_to allow_value('https://s3.amazonaws.com/invalid-bucket/uploads/1233443/filename.jpg').for(:value).with_message('is not valid') }
      it { is_expected.to allow_value('https://s3.amazonaws.com/brandscopic-dev/uploads/1233443/filename.jpg').for(:value) }
    end

    describe 'for text fields' do
      describe "when it's required" do
        let(:form_field) do
          create(:form_field_text,
                 settings: {},
                 fieldable: create(:activity_type, company_id: 1),
                 required: true)
        end
        it { is_expected.to_not allow_value(nil).for(:value) }
        it { is_expected.to_not allow_value('').for(:value) }
        it { is_expected.to allow_value('hola' * 100).for(:value) }
        it { is_expected.to allow_value('a').for(:value) }
      end

      describe "when doesn't have range validation rules" do
        let(:form_field) do
          create(:form_field_text,
                 settings: {},
                 fieldable: create(:activity_type, company_id: 1),
                 required: false)
        end
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.to allow_value('h').for(:value) }
        it { is_expected.to allow_value('hola ahi').for(:value) }
        it { is_expected.to allow_value('hola ' * 100).for(:value) }
      end

      describe 'when range format is characters' do
        let(:form_field) do
          create(:form_field_text,
                 settings: { 'range_format' => 'characters', 'range_min' => '2', 'range_max' => '4' },
                 fieldable: create(:activity_type, company_id: 1),
                 required: false)
        end
        before { subject.form_field_id = form_field.id }
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.not_to allow_value('a').for(:value).with_message('is invalid') }
        it { is_expected.to allow_value('hola').for(:value) }
        it { is_expected.not_to allow_value('cinco').for(:value).with_message('is invalid') }
      end

      describe 'when range format is words' do
        let(:form_field) do
          create(:form_field_text,
                 settings: { 'range_format' => 'words', 'range_min' => '2', 'range_max' => '4' },
                 fieldable: create(:activity_type, company_id: 1),
                 required: false)
        end
        before { subject.form_field_id = form_field.id }
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.not_to allow_value('uno').for(:value).with_message('is invalid') }
        it { is_expected.to allow_value('uno dos tres').for(:value) }
        it { is_expected.not_to allow_value('uno dos tres cuatro cinco').for(:value).with_message('is invalid') }
      end

      describe 'when have a range-min but not range-max validation' do
        let(:form_field) do
          create(:form_field_text,
                 settings: { 'range_format' => 'words', 'range_min' => '2', 'range_max' => '' },
                 fieldable: create(:activity_type, company_id: 1),
                 required: false)
        end
        before { subject.form_field_id = form_field.id }
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.to allow_value('hola ahi').for(:value) }
        it { is_expected.to allow_value('hola ' * 100).for(:value) }
        it { is_expected.not_to allow_value('h').for(:value) }
        it { is_expected.not_to allow_value('hola').for(:value) }
      end

      describe 'when have a range-max but not range-min validation' do
        let(:form_field) do
          create(:form_field_text,
                 settings: { 'range_format' => 'characters', 'range_min' => '', 'range_max' => '2' },
                 fieldable: create(:activity_type, company_id: 1),
                 required: false)
        end
        before { subject.form_field_id = form_field.id }
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.to allow_value('12').for(:value) }
        it { is_expected.to allow_value('ho').for(:value) }
        it { is_expected.not_to allow_value('hol').for(:value) }
        it { is_expected.not_to allow_value('hola ahi').for(:value) }
      end

    end

    describe 'for text area fields' do
      describe "when it's required" do
        let(:form_field) do
          create(:form_field_text_area,
                 type: 'FormField::TextArea',
                 settings: {},
                 fieldable: create(:activity_type, company_id: 1),
                 required: true)
        end
        it { is_expected.to_not allow_value(nil).for(:value) }
        it { is_expected.to_not allow_value('').for(:value) }
        it { is_expected.to allow_value('hola' * 100).for(:value) }
        it { is_expected.to allow_value('a').for(:value) }
      end

      describe "when doesn't have range validation rules" do
        let(:form_field) do
          create(:form_field_text_area,
                 settings: {},
                 fieldable: create(:activity_type, company_id: 1),
                 required: false)
        end
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.to allow_value('hola').for(:value) }
        it { is_expected.to allow_value('hola' * 100).for(:value) }
      end

      describe 'when range format is characters' do
        let(:form_field) do
          create(:form_field_text_area,
                 settings: { 'range_format' => 'characters', 'range_min' => '2', 'range_max' => '4' },
                 fieldable: create(:activity_type, company_id: 1),
                 required: false)
        end
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.not_to allow_value('a').for(:value).with_message('is invalid') }
        it { is_expected.to allow_value('hola').for(:value) }
        it { is_expected.not_to allow_value('cinco').for(:value).with_message('is invalid') }
      end

      describe 'when range format is words' do
        let(:form_field) do
          create(:form_field_text_area,
                             settings: { 'range_format' => 'words', 'range_min' => '2', 'range_max' => '4' },
                             fieldable: create(:activity_type, company_id: 1),
                             required: false)
        end
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.not_to allow_value('uno').for(:value).with_message('is invalid') }
        it { is_expected.to allow_value('uno dos tres').for(:value) }
        it { is_expected.not_to allow_value('uno dos tres cuatro cinco').for(:value).with_message('is invalid') }
      end
    end

    describe 'for percentage fields' do
      describe 'when not associated to a KPI' do
        let(:form_field) do
          create(:form_field_percentage,
                 options: [create(:form_field_option, name: 'Opt1'), create(:form_field_option, name: 'Opt2')],
                 fieldable: create(:activity_type, company_id: 1),
                 required: false)
        end
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.to allow_value(form_field.options[0].id => 50, form_field.options[1].id => 50).for(:value) }
        it { is_expected.to allow_value(form_field.options[0].id.to_s => 50, form_field.options[1].id.to_s => 50).for(:value) }
        it { is_expected.to allow_value(form_field.options[0].id => '', form_field.options[1].id => '').for(:value) }
        it { is_expected.to allow_value(form_field.options[0].id.to_s => '50', form_field.options[1].id.to_s => '50').for(:value) }
        it { is_expected.not_to allow_value(form_field.options[0].id => 'xx', form_field.options[1].id => 'uno').for(:value) }
        it { is_expected.not_to allow_value(form_field.options[0].id => 40, form_field.options[1].id => 10).for(:value) }
        it { is_expected.not_to allow_value(999 => 10, 888 => 90).for(:value) }
        it { is_expected.not_to allow_value(1).for(:value) }

        describe 'when it is required' do
          before { subject.form_field.required = true }
          it { is_expected.not_to allow_value(999 => 10, 888 => 90).for(:value) }
          it { is_expected.not_to allow_value('sdfsd').for(:value) }
          it { is_expected.not_to allow_value(1).for(:value) }
          it { is_expected.to allow_value(form_field.options[0].id => 50, form_field.options[1].id => 50).for(:value) }
          it { is_expected.to allow_value(form_field.options[0].id.to_s => 50, form_field.options[1].id.to_s => 50).for(:value) }
          it { is_expected.to_not allow_value(form_field.options[0].id.to_s => 10, form_field.options[1].id.to_s => 10).for(:value) }
        end
      end

      describe 'when associated to a KPI' do
        let(:form_field) do
          create(:form_field_percentage,
                 kpi: kpi, fieldable: create(:activity_type, company_id: 1),
                 required: false)
        end
        let(:kpi) do
          create(:kpi, kpi_type: 'percentage',
                       kpis_segments: [create(:kpis_segment), create(:kpis_segment)])
        end
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.to allow_value(kpi.kpis_segments[0].id => 50, kpi.kpis_segments[1].id => 50).for(:value) }
        it { is_expected.to allow_value(kpi.kpis_segments[0].id.to_s => 50, kpi.kpis_segments[1].id.to_s => 50).for(:value) }
        it { is_expected.to allow_value(kpi.kpis_segments[0].id => '', kpi.kpis_segments[1].id => '').for(:value) }
        it { is_expected.not_to allow_value(kpi.kpis_segments[0].id => 'xx', kpi.kpis_segments[1].id => 'uno').for(:value) }
        it { is_expected.not_to allow_value(kpi.kpis_segments[0].id => 40, kpi.kpis_segments[1].id => 10).for(:value) }
        it { is_expected.not_to allow_value(999 => 10, 888 => 90).for(:value) }
        it { is_expected.not_to allow_value(1).for(:value) }

        describe 'when it is required' do
          before { subject.form_field.required = true }

          it { is_expected.not_to allow_value(999 => 10, 888 => 90).for(:value) }
          it { is_expected.not_to allow_value('sdfsd').for(:value) }
          it { is_expected.not_to allow_value(1).for(:value) }
          it { is_expected.to allow_value(kpi.kpis_segments[0].id => 50, kpi.kpis_segments[1].id => 50).for(:value) }
          it { is_expected.to allow_value(kpi.kpis_segments[0].id.to_s => 50, kpi.kpis_segments[1].id.to_s => 50).for(:value) }
          it { is_expected.to_not allow_value(kpi.kpis_segments[0].id.to_s => 10, kpi.kpis_segments[1].id.to_s => 10).for(:value) }
        end
      end
    end

    describe 'for summation fields' do
      let(:form_field) do
        create(:form_field_summation,
                            options: [create(:form_field_option, name: 'Opt1'), create(:form_field_option, name: 'Opt2')],
                            fieldable: create(:activity_type, company_id: 1),
                            required: false)
      end
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.to allow_value(form_field.options[0].id => 100, form_field.options[1].id => 200).for(:value) }
      it { is_expected.to allow_value(form_field.options[0].id.to_s => 50, form_field.options[1].id.to_s => 50).for(:value) }
      it { is_expected.to allow_value(form_field.options[0].id => '', form_field.options[1].id => '').for(:value) }
      it { is_expected.not_to allow_value(999 => 10, 888 => 90).for(:value) }
      it { is_expected.not_to allow_value(1).for(:value) }

      describe 'when it is required' do
        before { subject.form_field.required = true }
        it { is_expected.not_to allow_value(999 => 1000, 888 => 90).for(:value) }
        it { is_expected.not_to allow_value('sdfsd').for(:value) }
        it { is_expected.not_to allow_value(1).for(:value) }
        it { is_expected.to allow_value(form_field.options[0].id => 50, form_field.options[1].id => 50).for(:value) }
        it { is_expected.to allow_value(form_field.options[0].id.to_s => 50, form_field.options[1].id.to_s => 50).for(:value) }
      end
    end

    describe 'for likert scale fields' do
      let(:form_field) do
        create(:form_field_likert_scale,
               options: [create(:form_field_option, name: 'Opt1'), create(:form_field_option, name: 'Opt2')],
               statements: [create(:form_field_statement, name: 'Stat1'), create(:form_field_statement, name: 'Stat2')],
               fieldable: create(:activity_type, company_id: 1), multiple: false,
               required: false)
      end

      describe 'when it is radio buttons' do
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.to allow_value(form_field.statements[0].id => form_field.options[0].id, form_field.statements[1].id => form_field.options[0].id).for(:value) }
        it { is_expected.to allow_value(form_field.statements[0].id.to_s => form_field.options[0].id.to_s, form_field.statements[1].id.to_s => form_field.options[1].id.to_s).for(:value) }
        it { is_expected.to allow_value(form_field.statements[0].id => '', form_field.statements[1].id => '').for(:value) }
        it { is_expected.to allow_value(form_field.statements[0].id => form_field.options[0].id.to_s, form_field.statements[1].id => '').for(:value) }
        it { is_expected.not_to allow_value(999 => 10, 888 => 90).for(:value) }
        it { is_expected.not_to allow_value(1).for(:value) }
      end

      describe 'when it is checkboxes' do
        before { subject.form_field.multiple = true }
        it { is_expected.to allow_value(nil).for(:value) }
        it { is_expected.to allow_value('').for(:value) }
        it { is_expected.to allow_value(form_field.statements[0].id => [form_field.options[0].id], form_field.statements[1].id => [form_field.options[0].id]).for(:value) }
        it { is_expected.to allow_value(form_field.statements[0].id.to_s => [form_field.options[0].id.to_s], form_field.statements[1].id.to_s => [form_field.options[1].id.to_s]).for(:value) }
        it { is_expected.to allow_value(form_field.statements[0].id => '', form_field.statements[1].id => '').for(:value) }
        it { is_expected.to allow_value(form_field.statements[0].id => [form_field.options[0].id.to_s], form_field.statements[1].id => '').for(:value) }
        it { is_expected.to allow_value(form_field.statements[0].id => [form_field.options[0].id, form_field.options[1].id], form_field.statements[1].id => [form_field.options[0].id]).for(:value) }
        it { is_expected.to allow_value(form_field.statements[0].id.to_s => [form_field.options[0].id.to_s], form_field.statements[1].id.to_s => [form_field.options[0].id.to_s, form_field.options[1].id.to_s]).for(:value) }
        it { is_expected.not_to allow_value(999 => [10], 888 => [90, 100]).for(:value) }
        it { is_expected.not_to allow_value(1).for(:value) }
      end

      describe 'when it is required' do
        before { subject.form_field.required = true }
        it { is_expected.not_to allow_value(999 => 1000, 888 => 90).for(:value) }
        it { is_expected.not_to allow_value('sdfsd').for(:value) }
        it { is_expected.not_to allow_value(1).for(:value) }
        it { is_expected.to allow_value(form_field.statements[0].id => form_field.options[0].id, form_field.statements[1].id => form_field.options[0].id).for(:value) }
        it { is_expected.to allow_value(form_field.statements[0].id.to_s => form_field.options[1].id, form_field.statements[1].id.to_s => form_field.options[0].id).for(:value) }
      end
    end

    describe 'for checkbox fields' do
      let(:form_field) do
        create(:form_field_checkbox,
               options: [create(:form_field_option, name: 'Opt1'), create(:form_field_option, name: 'Opt2')],
               fieldable: create(:activity_type, company_id: 1),
               required: false)
      end
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value([form_field.options[0].id, form_field.options[1].id]).for(:value) }
      it { is_expected.to allow_value([form_field.options[0].id]).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.to_not allow_value(["#{form_field.options[1].id}x"]).for(:value) }
      it { is_expected.not_to allow_value([form_field.options[0].id + 100]).for(:value) }

      describe 'when it is required' do
        before { subject.form_field.required = true }
        it { is_expected.not_to allow_value([]).for(:value) }
        it { is_expected.not_to allow_value('sdfsd').for(:value) }
        it { is_expected.not_to allow_value(' ').for(:value) }
        it { is_expected.to allow_value([form_field.options[0].id, form_field.options[1].id]).for(:value) }
        it { is_expected.to allow_value([form_field.options[0].id.to_s, form_field.options[1].id.to_s]).for(:value) }
      end
    end

    describe 'for radio fields' do
      let(:form_field) do
        create(:form_field_radio,
               options: [create(:form_field_option, name: 'Opt1'), create(:form_field_option, name: 'Opt2')],
               fieldable: create(:activity_type, company_id: 1),
               required: false)
      end
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value(form_field.options[0].id).for(:value) }
      it { is_expected.to allow_value(form_field.options[1].id.to_s).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.to_not allow_value(0).for(:value) }
      it { is_expected.to_not allow_value("#{form_field.options[1].id}x").for(:value) }
      it { is_expected.not_to allow_value(form_field.options[0].id + 100).for(:value) }
      it { is_expected.not_to allow_value('sdfsd').for(:value) }

      describe 'when it is required' do
        before { subject.form_field.required = true }
        it { is_expected.not_to allow_value('').for(:value) }
        it { is_expected.not_to allow_value(0).for(:value) }
        it { is_expected.not_to allow_value(' ').for(:value) }
        it { is_expected.not_to allow_value(nil).for(:value) }
        it { is_expected.to allow_value(form_field.options[0].id).for(:value) }
        it { is_expected.to allow_value(form_field.options[1].id.to_s).for(:value) }
      end
    end
  end
end
