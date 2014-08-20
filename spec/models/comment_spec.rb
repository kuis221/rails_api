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

require 'rails_helper'

describe Comment, :type => :model do
  it { is_expected.to belong_to(:commentable) }

  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to validate_presence_of(:commentable_id) }
  it { is_expected.to validate_numericality_of(:commentable_id) }
  it { is_expected.to validate_presence_of(:commentable_type) }
end
