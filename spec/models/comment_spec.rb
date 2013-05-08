require 'spec_helper'

describe Comment do
  it { should belong_to(:commentable) }

  it { should allow_mass_assignment_of(:content) }

  it { should validate_presence_of(:content) }
  it { should validate_presence_of(:created_by_id) }
  it { should validate_numericality_of(:created_by_id) }
end
