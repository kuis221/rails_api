# == Schema Information
#
# Table name: permissions
#
#  id            :integer          not null, primary key
#  role_id       :integer
#  action        :string(255)
#  subject_class :string(255)
#  subject_id    :string(255)
#  mode          :string(255)      default("none")
#

FactoryGirl.define do
  factory :permission do
    role_id 1
    action ''
    subject_class ''
    subject_id nil
    mode 'none'
  end
end
