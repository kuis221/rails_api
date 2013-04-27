# == Schema Information
#
# Table name: teams_users
#
#  id         :integer          not null, primary key
#  team_id    :integer
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe TeamsUser do
  it { should belong_to(:team) }
  it { should belong_to(:user) }
end
