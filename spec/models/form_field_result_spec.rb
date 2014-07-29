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

describe FormFieldResult do
  it { should belong_to(:resultable) }
  it { should belong_to(:form_field) }

  it { should validate_presence_of(:form_field_id) }
  it { should validate_numericality_of(:form_field_id) }

  describe "for required fields" do
    before { subject.form_field = FactoryGirl.build(:form_field, type: 'FormField::Number', required: true) }
    it { should_not allow_value(nil).for(:value) }
    it { should_not allow_value('').for(:value) }
    it { should allow_value('1').for(:value) }
    it { should allow_value(1).for(:value) }
  end

  describe "for non required fields" do
    before { subject.form_field = FactoryGirl.build(:form_field, type: 'FormField::Number', required: false) }
    it { should allow_value(nil).for(:value) }
    it { should allow_value('').for(:value) }
    it { should allow_value('1').for(:value) }
    it { should allow_value(1).for(:value) }
  end

  describe "for numeric fields" do
    before { subject.form_field_id = FactoryGirl.create(:form_field, type: 'FormField::Number', fieldable: FactoryGirl.create(:activity_type, company_id: 1), required: false).id }
    it { should validate_numericality_of(:value) }
    it { should allow_value(nil).for(:value) }
    it { should allow_value(nil).for(:value) }
    it { should allow_value('').for(:value) }
    it { should allow_value('1').for(:value) }
    it { should allow_value(1).for(:value) }
  end

  describe "for photo fields" do
    before { subject.form_field_id = FactoryGirl.create(:form_field, type: 'FormField::Photo', fieldable: FactoryGirl.create(:activity_type, company_id: 1), required: false).id }
    it { should allow_value(nil).for(:value) }
    it { should allow_value(nil).for(:value) }
    it { should allow_value('').for(:value) }
    it { should_not allow_value('sdfsd').for(:value).with_message('is not valid') }
    it { should_not allow_value('https://s3.amazonaws.com/invalid-bucket/uploads/1233443/filename.jpg').for(:value).with_message('is not valid') }
    it { should allow_value('https://s3.amazonaws.com/brandscopic-test/uploads/1233443/filename.jpg').for(:value) }
  end

  describe "for percentage fields" do
    let(:form_field) { FactoryGirl.create(:form_field,
      type: 'FormField::Percentage',
      options: [FactoryGirl.create(:form_field_option, name: 'Opt1'), FactoryGirl.create(:form_field_option, name: 'Opt2')],
      fieldable: FactoryGirl.create(:activity_type, company_id: 1),
      required: false) }
    before { subject.form_field_id = form_field.id }
    it { should allow_value(nil).for(:value) }
    it { should allow_value(nil).for(:value) }
    it { should allow_value('').for(:value) }
    it { should allow_value({form_field.options[0].id => 50, form_field.options[1].id => 50}).for(:value) }
    it { should allow_value({form_field.options[0].id.to_s => 50, form_field.options[1].id.to_s => 50}).for(:value) }
    it { should_not allow_value({form_field.options[0].id => 40, form_field.options[1].id => 10}).for(:value) }
    it { should_not allow_value({999 => 10, 888 => 90}).for(:value) }
    it { should_not allow_value('sdfsd').for(:value) }
    it { should_not allow_value(1).for(:value) }
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
      expect(r.save).to be_true
    end
  end
end
