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

require 'spec_helper'

describe Survey do
  it { should belong_to(:event) }
  it { should have_many(:surveys_answers) }

  it { should allow_mass_assignment_of(:surveys_answers_attributes) }

  it { should_not allow_mass_assignment_of(:id) }
  it { should_not allow_mass_assignment_of(:event_id) }
  it { should_not allow_mass_assignment_of(:active) }
  it { should_not allow_mass_assignment_of(:created_by_id) }
  it { should_not allow_mass_assignment_of(:updated_by_id) }
  it { should_not allow_mass_assignment_of(:created_at) }
  it { should_not allow_mass_assignment_of(:updated_at) }

  it { should accept_nested_attributes_for(:surveys_answers) }
end
