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

require 'rails_helper'

RSpec.describe DocumentFolder, :type => :model do
  it { is_expected.to belong_to(:company) }
  it { is_expected.to belong_to(:parent) }
  it { is_expected.to belong_to(:folderable) }

  it { is_expected.to validate_presence_of(:name) }

  describe "uniqueness" do
    before{  FactoryGirl.build(:document_folder) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "#activate" do
    let(:folder) { FactoryGirl.build(:document_folder, active: false) }

    it "should return the active value as true" do
      folder.activate!
      folder.reload
      expect(folder.active).to be_truthy
    end
  end

  describe "#deactivate" do
    let(:folder) { FactoryGirl.build(:document_folder, active: false) }

    it "should return the active value as false" do
      folder.deactivate!
      folder.reload
      expect(folder.active).to be_falsey
    end
  end
end
