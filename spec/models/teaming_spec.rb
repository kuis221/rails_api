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

end
