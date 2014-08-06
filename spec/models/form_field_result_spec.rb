# == Schema Information
#
# Table name: activity_results
#
#  id            :integer          not null, primary key
#  activity_id   :integer
#  form_field_id :integer
#  value         :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  hash_value    :hstore
#  scalar_value  :decimal(10, 2)   default(0.0)
#

require 'spec_helper'

describe FormFieldResult, :type => :model do
  it { is_expected.to belong_to(:resultable) }
  it { is_expected.to belong_to(:form_field) }

  it { is_expected.to validate_presence_of(:form_field_id) }
  it { is_expected.to validate_numericality_of(:form_field_id) }

  describe "for required fields" do
    before { subject.form_field = FactoryGirl.build(:form_field, type: 'FormField::Number', required: true) }
    it { is_expected.not_to allow_value(nil).for(:value) }
    it { is_expected.not_to allow_value('').for(:value) }
    it { is_expected.to allow_value('1').for(:value) }
    it { is_expected.to allow_value(1).for(:value) }
  end

  describe "for non required fields" do
    before { subject.form_field = FactoryGirl.build(:form_field, type: 'FormField::Number', required: false) }
    it { is_expected.to allow_value(nil).for(:value) }
    it { is_expected.to allow_value('').for(:value) }
    it { is_expected.to allow_value('1').for(:value) }
    it { is_expected.to allow_value(1).for(:value) }
  end

  describe "for numeric fields" do
    describe "when doesn't have range validation rules" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::Number',
        settings: {},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to validate_numericality_of(:value) }
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.to allow_value('1').for(:value) }
      it { is_expected.to allow_value(1).for(:value) }
    end

    describe "when range format is digits" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::Number',
        settings: {'range_format' => 'digits', 'range_min' => '2', 'range_max' => '4'},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.not_to allow_value('1').for(:value).with_message('is invalid') }
      it { is_expected.to allow_value(1234).for(:value) }
      it { is_expected.to allow_value('1234').for(:value) }
      it { is_expected.to allow_value('1.234').for(:value) }
      it { is_expected.to allow_value(1.234).for(:value) }
      it { is_expected.not_to allow_value('12345').for(:value).with_message('is invalid') }
    end

    describe "when range format is value" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::Number',
        settings: {'range_format' => 'value', 'range_min' => '2', 'range_max' => '4'},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
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

  describe "for currency fields" do
    describe "when doesn't have range validation rules" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::Currency',
        settings: {},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to validate_numericality_of(:value) }
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.to allow_value('1').for(:value) }
      it { is_expected.to allow_value(1).for(:value) }
    end

    describe "when range format is digits" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::Currency',
        settings: {'range_format' => 'digits', 'range_min' => '2', 'range_max' => '4'},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.not_to allow_value('1').for(:value).with_message('is invalid') }
      it { is_expected.to allow_value(1234).for(:value) }
      it { is_expected.to allow_value('1234').for(:value) }
      it { is_expected.to allow_value('1.234').for(:value) }
      it { is_expected.to allow_value(1.234).for(:value) }
      it { is_expected.not_to allow_value('12345').for(:value).with_message('is invalid') }
    end

    describe "when range format is value" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::Currency',
        settings: {'range_format' => 'value', 'range_min' => '2', 'range_max' => '4'},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
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

  describe "for photo fields" do
    before { subject.form_field_id = FactoryGirl.create(:form_field, type: 'FormField::Photo', fieldable: FactoryGirl.create(:activity_type, company_id: 1), required: false).id }
    it { is_expected.to allow_value(nil).for(:value) }
    it { is_expected.to allow_value('').for(:value) }
    it { is_expected.not_to allow_value('sdfsd').for(:value).with_message('is not valid') }
    it { is_expected.not_to allow_value('https://s3.amazonaws.com/invalid-bucket/uploads/1233443/filename.jpg').for(:value).with_message('is not valid') }
    it { is_expected.to allow_value('https://s3.amazonaws.com/brandscopic-test/uploads/1233443/filename.jpg').for(:value) }
  end

  describe "for text fields" do
    describe "when it's required" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::Text',
        settings: {},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: true) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to_not allow_value(nil).for(:value) }
      it { is_expected.to_not allow_value('').for(:value) }
      it { is_expected.to allow_value('hola'*100).for(:value) }
      it { is_expected.to allow_value('a').for(:value) }
    end

    describe "when doesn't have range validation rules" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::Text',
        settings: {},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.to allow_value('h').for(:value) }
      it { is_expected.to allow_value('hola ahi').for(:value) }
      it { is_expected.to allow_value('hola '*100).for(:value) }
    end

    describe "when range format is characters" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::Text',
        settings: {'range_format' => 'characters', 'range_min' => '2', 'range_max' => '4'},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.not_to allow_value('a').for(:value).with_message('is invalid') }
      it { is_expected.to allow_value('hola').for(:value) }
      it { is_expected.not_to allow_value('cinco').for(:value).with_message('is invalid') }
    end

    describe "when range format is words" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::Text',
        settings: {'range_format' => 'words', 'range_min' => '2', 'range_max' => '4'},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.not_to allow_value('uno').for(:value).with_message('is invalid') }
      it { is_expected.to allow_value('uno dos tres').for(:value) }
      it { is_expected.not_to allow_value('uno dos tres cuatro cinco').for(:value).with_message('is invalid') }
    end

    describe "when have a range-min but not range-max validation" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::Text',
        settings: {'range_format' => 'words', 'range_min' => '2', 'range_max' => ''},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.to allow_value('hola ahi').for(:value) }
      it { is_expected.to allow_value('hola '*100).for(:value) }
      it { is_expected.not_to allow_value('h').for(:value) }
      it { is_expected.not_to allow_value('hola').for(:value) }
    end

    describe "when have a range-max but not range-min validation" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::Text',
        settings: {'range_format' => 'characters', 'range_min' => '', 'range_max' => '2'},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.to allow_value('12').for(:value) }
      it { is_expected.to allow_value('ho').for(:value) }
      it { is_expected.not_to allow_value('hol').for(:value) }
      it { is_expected.not_to allow_value('hola ahi').for(:value) }
    end

  end

  describe "for text area fields" do
    describe "when it's required" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::TextArea',
        settings: {},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: true) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to_not allow_value(nil).for(:value) }
      it { is_expected.to_not allow_value('').for(:value) }
      it { is_expected.to allow_value('hola'*100).for(:value) }
      it { is_expected.to allow_value('a').for(:value) }
    end

    describe "when doesn't have range validation rules" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::TextArea',
        settings: {},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.to allow_value('hola').for(:value) }
      it { is_expected.to allow_value('hola'*100).for(:value) }
    end

    describe "when range format is characters" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::TextArea',
        settings: {'range_format' => 'characters', 'range_min' => '2', 'range_max' => '4'},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.not_to allow_value('a').for(:value).with_message('is invalid') }
      it { is_expected.to allow_value('hola').for(:value) }
      it { is_expected.not_to allow_value('cinco').for(:value).with_message('is invalid') }
    end

    describe "when range format is words" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::Text',
        settings: {'range_format' => 'words', 'range_min' => '2', 'range_max' => '4'},
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.not_to allow_value('uno').for(:value).with_message('is invalid') }
      it { is_expected.to allow_value('uno dos tres').for(:value) }
      it { is_expected.not_to allow_value('uno dos tres cuatro cinco').for(:value).with_message('is invalid') }
    end
  end

  describe "for percentage fields" do
    describe "when not associated to a KPI" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::Percentage',
        options: [FactoryGirl.create(:form_field_option, name: 'Opt1'), FactoryGirl.create(:form_field_option, name: 'Opt2')],
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.to allow_value({form_field.options[0].id => 50, form_field.options[1].id => 50}).for(:value) }
      it { is_expected.to allow_value({form_field.options[0].id.to_s => 50, form_field.options[1].id.to_s => 50}).for(:value) }
      it { is_expected.to allow_value({form_field.options[0].id => '', form_field.options[1].id => ''}).for(:value) }
      it { is_expected.not_to allow_value({form_field.options[0].id => 'xx', form_field.options[1].id => 'uno'}).for(:value) }
      it { is_expected.not_to allow_value({form_field.options[0].id => 40, form_field.options[1].id => 10}).for(:value) }
      it { is_expected.not_to allow_value({999 => 10, 888 => 90}).for(:value) }
      it { is_expected.not_to allow_value('sdfsd').for(:value) }
      it { is_expected.not_to allow_value(1).for(:value) }

      describe "when it is required" do
        before { subject.form_field.required = true }
        it { is_expected.not_to allow_value({999 => 10, 888 => 90}).for(:value) }
        it { is_expected.not_to allow_value('sdfsd').for(:value) }
        it { is_expected.not_to allow_value(1).for(:value) }
        it { is_expected.to allow_value({form_field.options[0].id => 50, form_field.options[1].id => 50}).for(:value) }
        it { is_expected.to allow_value({form_field.options[0].id.to_s => 50, form_field.options[1].id.to_s => 50}).for(:value) }
        it { is_expected.to_not allow_value({form_field.options[0].id.to_s => 10, form_field.options[1].id.to_s => 10}).for(:value) }
      end
    end

    describe "when associated to a KPI" do
      let(:form_field) { FactoryGirl.create(:form_field,
        type: 'FormField::Percentage',
        kpi: kpi,
        fieldable: FactoryGirl.create(:activity_type, company_id: 1),
        required: false) }
      let(:kpi) { FactoryGirl.create(:kpi,
        kpi_type: 'percentage',
        kpis_segments: [FactoryGirl.create(:kpis_segment), FactoryGirl.create(:kpis_segment)]) }
      before { subject.form_field_id = form_field.id }
      it { is_expected.to allow_value(nil).for(:value) }
      it { is_expected.to allow_value('').for(:value) }
      it { is_expected.to allow_value({kpi.kpis_segments[0].id => 50, kpi.kpis_segments[1].id => 50}).for(:value) }
      it { is_expected.to allow_value({kpi.kpis_segments[0].id.to_s => 50, kpi.kpis_segments[1].id.to_s => 50}).for(:value) }
      it { is_expected.to allow_value({kpi.kpis_segments[0].id => '', kpi.kpis_segments[1].id => ''}).for(:value) }
      it { is_expected.not_to allow_value({kpi.kpis_segments[0].id => 'xx', kpi.kpis_segments[1].id => 'uno'}).for(:value) }
      it { is_expected.not_to allow_value({kpi.kpis_segments[0].id => 40, kpi.kpis_segments[1].id => 10}).for(:value) }
      it { is_expected.not_to allow_value({999 => 10, 888 => 90}).for(:value) }
      it { is_expected.not_to allow_value('sdfsd').for(:value) }
      it { is_expected.not_to allow_value(1).for(:value) }

      describe "when it is required" do
        before { subject.form_field.required = true }
        it { is_expected.not_to allow_value({999 => 10, 888 => 90}).for(:value) }
        it { is_expected.not_to allow_value('sdfsd').for(:value) }
        it { is_expected.not_to allow_value(1).for(:value) }
        it { is_expected.to allow_value({kpi.kpis_segments[0].id => 50, kpi.kpis_segments[1].id => 50}).for(:value) }
        it { is_expected.to allow_value({kpi.kpis_segments[0].id.to_s => 50, kpi.kpis_segments[1].id.to_s => 50}).for(:value) }
        it { is_expected.to_not allow_value({kpi.kpis_segments[0].id.to_s => 10, kpi.kpis_segments[1].id.to_s => 10}).for(:value) }
      end
    end
  end

  describe "for summation fields" do
    let(:form_field) { FactoryGirl.create(:form_field,
      type: 'FormField::Summation',
      options: [FactoryGirl.create(:form_field_option, name: 'Opt1'), FactoryGirl.create(:form_field_option, name: 'Opt2')],
      fieldable: FactoryGirl.create(:activity_type, company_id: 1),
      required: false) }
    before { subject.form_field_id = form_field.id }
    it { is_expected.to allow_value(nil).for(:value) }
    it { is_expected.to allow_value('').for(:value) }
    it { is_expected.to allow_value({form_field.options[0].id => 100, form_field.options[1].id => 200}).for(:value) }
    it { is_expected.to allow_value({form_field.options[0].id.to_s => 50, form_field.options[1].id.to_s => 50}).for(:value) }
    it { is_expected.to allow_value({form_field.options[0].id => '', form_field.options[1].id => ''}).for(:value) }
    it { is_expected.not_to allow_value({999 => 10, 888 => 90}).for(:value) }
    it { is_expected.not_to allow_value('sdfsd').for(:value) }
    it { is_expected.not_to allow_value(1).for(:value) }

    describe "when it is required" do
      before { subject.form_field.required = true }
      it { is_expected.not_to allow_value({999 => 1000, 888 => 90}).for(:value) }
      it { is_expected.not_to allow_value('sdfsd').for(:value) }
      it { is_expected.not_to allow_value(1).for(:value) }
      it { is_expected.to allow_value({form_field.options[0].id => 50, form_field.options[1].id => 50}).for(:value) }
      it { is_expected.to allow_value({form_field.options[0].id.to_s => 50, form_field.options[1].id.to_s => 50}).for(:value) }
    end
  end

  describe "for likert scale fields" do
    let(:form_field) { FactoryGirl.create(:form_field,
      type: 'FormField::LikertScale',
      options: [FactoryGirl.create(:form_field_option, name: 'Opt1'), FactoryGirl.create(:form_field_option, name: 'Opt2')],
      statements: [FactoryGirl.create(:form_field_statement, name: 'Stat1'), FactoryGirl.create(:form_field_statement, name: 'Stat2')],
      fieldable: FactoryGirl.create(:activity_type, company_id: 1),
      required: false) }
    before { subject.form_field_id = form_field.id }
    it { is_expected.to allow_value(nil).for(:value) }
    it { is_expected.to allow_value('').for(:value) }
    it { is_expected.to allow_value({form_field.statements[0].id => form_field.options[0].id, form_field.statements[1].id => form_field.options[0].id}).for(:value) }
    it { is_expected.to allow_value({form_field.statements[0].id.to_s => form_field.options[0].id.to_s, form_field.statements[1].id.to_s => form_field.options[1].id.to_s}).for(:value) }
    it { is_expected.to allow_value({form_field.statements[0].id => '', form_field.statements[1].id => ''}).for(:value) }
    it { is_expected.to allow_value({form_field.statements[0].id => form_field.options[0].id.to_s, form_field.statements[1].id => ''}).for(:value) }
    it { is_expected.not_to allow_value({999 => 10, 888 => 90}).for(:value) }
    it { is_expected.not_to allow_value('sdfsd').for(:value) }
    it { is_expected.not_to allow_value(1).for(:value) }

    describe "when it is required" do
      before { subject.form_field.required = true }
      it { is_expected.not_to allow_value({999 => 1000, 888 => 90}).for(:value) }
      it { is_expected.not_to allow_value('sdfsd').for(:value) }
      it { is_expected.not_to allow_value(1).for(:value) }
      it { is_expected.to allow_value({form_field.statements[0].id => form_field.options[0].id, form_field.statements[1].id => form_field.options[0].id}).for(:value) }
      it { is_expected.to allow_value({form_field.statements[0].id.to_s => form_field.options[1].id, form_field.statements[1].id.to_s => form_field.options[0].id}).for(:value) }
    end
  end

  describe "for checkbox fields" do
    let(:form_field) { FactoryGirl.create(:form_field,
      type: 'FormField::Checkbox',
      options: [FactoryGirl.create(:form_field_option, name: 'Opt1'), FactoryGirl.create(:form_field_option, name: 'Opt2')],
      fieldable: FactoryGirl.create(:activity_type, company_id: 1),
      required: false) }
    before { subject.form_field_id = form_field.id }
    it { is_expected.to allow_value(nil).for(:value) }
    it { is_expected.to allow_value([form_field.options[0].id, form_field.options[1].id]).for(:value) }
    it { is_expected.to allow_value([form_field.options[0].id]).for(:value) }
    it { is_expected.to_not allow_value(["#{form_field.options[1].id}x"]).for(:value) }
    it { is_expected.to_not allow_value('').for(:value) }
    it { is_expected.not_to allow_value([form_field.options[0].id+100]).for(:value) }
    it { is_expected.not_to allow_value('sdfsd').for(:value) }

    describe "when it is required" do
      before { subject.form_field.required = true }
      it { is_expected.not_to allow_value([]).for(:value) }
      it { is_expected.not_to allow_value('sdfsd').for(:value) }
      it { is_expected.not_to allow_value(' ').for(:value) }
      it { is_expected.to allow_value([form_field.options[0].id, form_field.options[1].id]).for(:value) }
      it { is_expected.to allow_value([form_field.options[0].id.to_s, form_field.options[1].id.to_s]).for(:value) }
    end
  end

  describe "for radio fields" do
    let(:form_field) { FactoryGirl.create(:form_field,
      type: 'FormField::Radio',
      options: [FactoryGirl.create(:form_field_option, name: 'Opt1'), FactoryGirl.create(:form_field_option, name: 'Opt2')],
      fieldable: FactoryGirl.create(:activity_type, company_id: 1),
      required: false) }
    before { subject.form_field_id = form_field.id }
    it { is_expected.to allow_value(nil).for(:value) }
    it { is_expected.to allow_value(form_field.options[0].id).for(:value) }
    it { is_expected.to allow_value(form_field.options[1].id.to_s).for(:value) }
    it { is_expected.to allow_value('').for(:value) }
    it { is_expected.to_not allow_value(0).for(:value) }
    it { is_expected.to_not allow_value("#{form_field.options[1].id}x").for(:value) }
    it { is_expected.not_to allow_value(form_field.options[0].id+100).for(:value) }
    it { is_expected.not_to allow_value('sdfsd').for(:value) }

    describe "when it is required" do
      before { subject.form_field.required = true }
      it { is_expected.not_to allow_value('').for(:value) }
      it { is_expected.not_to allow_value(0).for(:value) }
      it { is_expected.not_to allow_value(' ').for(:value) }
      it { is_expected.not_to allow_value(nil).for(:value) }
      it { is_expected.to allow_value(form_field.options[0].id).for(:value) }
      it { is_expected.to allow_value(form_field.options[1].id.to_s).for(:value) }
    end
  end

  describe "prepare_for_store" do
    let(:form_field) { FactoryGirl.create(:form_field,
      type: 'FormField::Percentage',
      options: [FactoryGirl.create(:form_field_option, name: 'Opt1'), FactoryGirl.create(:form_field_option, name: 'Opt2')],
      fieldable: FactoryGirl.create(:activity_type, company_id: 1),
      required: false) }

    it "should assign the hash_value for hashed_fields" do
      r = FactoryGirl.build(:form_field_result, form_field_id: form_field.id)
      r.value = {form_field.options[0].id => 50, form_field.options[1].id => 50}
      r.valid?
      expect(r.hash_value).to eql({form_field.options[0].id => 50, form_field.options[1].id => 50})
      expect(r.save).to be_truthy
    end
  end
end
