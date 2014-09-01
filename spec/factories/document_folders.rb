# == Schema Information
#
# Table name: document_folders
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  parent_id       :integer
#  active          :boolean
#  documents_count :integer
#  company_id      :integer
#  created_at      :datetime
#  updated_at      :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :document_folder do
    name "MyString"
    parent nil
    active false
    documents_count 1
    company nil
  end
end
