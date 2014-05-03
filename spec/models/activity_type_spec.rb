# == Schema Information
#
# Table name: activity_types
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  active      :boolean          default(TRUE)
#  company_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'spec_helper'

describe ActivityType do
  it { should belong_to(:company) }
  it { should have_many(:form_fields) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:company_id) }
  it { should validate_numericality_of(:company_id) }

  describe "ensure_user_date_field" do
    it 'should create a UserDate field by default' do
      type = FactoryGirl.build(:activity_type)
      expect {
        type.save
      }.to change(type.form_fields, :count).by(1)
      expect(FormField.last.type).to eql 'FormField::UserDate'
    end

    it 'should NOT create a new UserDate if the activity already have one' do
      type = FactoryGirl.create(:activity_type)
      expect {
        type.name = 'Changed name'
        type.save
      }.to_not change(type.form_fields, :count).by(1)
      expect(FormField.last.type).to eql 'FormField::UserDate'
    end
  end
end
