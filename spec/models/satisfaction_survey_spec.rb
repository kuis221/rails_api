# == Schema Information
#
# Table name: satisfaction_surveys
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  session_id      :string(255)
#  rating          :string(255)
#  feedback        :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'rails_helper'

describe SatisfactionSurvey, type: :model do
  it { is_expected.to belong_to(:company_user) }
  it { is_expected.to validate_presence_of(:rating) }
end
