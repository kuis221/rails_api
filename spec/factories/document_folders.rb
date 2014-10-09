# == Schema Information
#
# Table name: document_folders
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  parent_id       :integer
#  active          :boolean          default(TRUE)
#  documents_count :integer
#  company_id      :integer
#  created_at      :datetime
#  updated_at      :datetime
#  folderable_id   :integer
#  folderable_type :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :document_folder do
    sequence(:name) { |n| "Folder #{n}" }
    parent nil
    active true
    documents_count 1
    company nil
  end
end
