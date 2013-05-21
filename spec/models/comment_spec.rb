# == Schema Information
#
# Table name: comments
#
#  id               :integer          not null, primary key
#  commentable_id   :integer
#  commentable_type :string(255)
#  content          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'spec_helper'

describe Comment do
  it { should belong_to(:commentable) }

  it { should allow_mass_assignment_of(:content) }

  it { should validate_presence_of(:content) }
  it { should validate_presence_of(:commentable_id) }
  it { should validate_numericality_of(:commentable_id) }
  it { should validate_presence_of(:commentable_type) }
end
