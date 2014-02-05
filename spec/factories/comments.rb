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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :comment do
    commentable nil
    content "MyText"
    created_by_id 1
    updated_by_id 1
  end
end
