# == Schema Information
#
# Table name: activity_types
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  active        :boolean          default("true")
#  company_id    :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :integer
#  updated_by_id :integer
#

require 'rails_helper'

describe ActivityType, type: :model do
  it { is_expected.to belong_to(:company) }
  it { is_expected.to have_many(:form_fields) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:company_id) }
  it { is_expected.to validate_numericality_of(:company_id) }

  describe 'ensure_user_date_field' do
    it 'should create a UserDate field by default' do
      type = build(:activity_type)
      expect do
        type.save
      end.to change(type.form_fields, :count).by(1)
      expect(FormField.last.type).to eql 'FormField::UserDate'
    end

    it 'should NOT create a new UserDate if the activity already have one' do
      type = create(:activity_type)
      expect do
        type.name = 'Changed name'
        type.save
      end.to_not change(type.form_fields, :count)
      expect(FormField.last.type).to eql 'FormField::UserDate'
    end
  end

  describe 'with_trending_fields' do
    let(:activity_type) { FactoryGirl.create(:activity_type) }
    let(:field) { FactoryGirl.create(:form_field, type: 'FormField::TextArea', fieldable: activity_type) }

    it 'results empty if no activity types have the needed fields' do
      expect(described_class.with_trending_fields).to be_empty
    end

    it 'results the activity type if have a text area field' do
      field.save
      expect(described_class.with_trending_fields).to match_array [activity_type]
    end

    it 'should return each activity type only once' do
      field.save
      field2 = FactoryGirl.create(:form_field, type: 'FormField::TextArea', fieldable: activity_type)

      expect(described_class.with_trending_fields).to match_array [activity_type]
    end
  end
end
