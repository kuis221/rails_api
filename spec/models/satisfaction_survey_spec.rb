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

require 'spec_helper'

describe SatisfactionSurvey do
  it { should belong_to(:company_user) }
  it { should validate_presence_of(:rating) }
end
