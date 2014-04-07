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

describe ActivityResult do
  it { should belong_to(:activity) }
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
end
