# == Schema Information
#
# Table name: surveys
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  created_by_id :integer
#  updated_by_id :integer
#  active        :boolean          default(TRUE)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'rails_helper'

describe Survey, type: :model do
  it { is_expected.to belong_to(:event) }
  it { is_expected.to have_many(:surveys_answers) }

  it { is_expected.to accept_nested_attributes_for(:surveys_answers) }

  describe '#activate' do
    let(:survey) { build(:survey, active: false) }

    it 'should return the active value as true' do
      survey.activate!
      survey.reload
      expect(survey.active).to be_truthy
    end
  end

  describe '#deactivate' do
    let(:survey) { build(:survey, active: false) }

    it 'should return the active value as false' do
      survey.deactivate!
      survey.reload
      expect(survey.active).to be_falsey
    end
  end
end
