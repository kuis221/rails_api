# == Schema Information
#
# Table name: teamings
#
#  id            :integer          not null, primary key
#  team_id       :integer
#  teamable_id   :integer
#  teamable_type :string(255)
#

require 'spec_helper'

describe Teaming do
  it { should belong_to(:team) }
  it { should belong_to(:teamable) }

  it { should_not allow_mass_assignment_of(:id) }
  it { should_not allow_mass_assignment_of(:team_id) }
  it { should_not allow_mass_assignment_of(:teamable_id) }
  it { should_not allow_mass_assignment_of(:teamable_type) }
end
