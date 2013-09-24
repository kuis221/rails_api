# == Schema Information
#
# Table name: attached_assets
#
#  id                :integer          not null, primary key
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  asset_type        :string(255)
#  attachable_id     :integer
#  attachable_type   :string(255)
#  created_by_id     :integer
#  updated_by_id     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  active            :boolean          default(TRUE)
#  direct_upload_url :string(255)
#  processed         :boolean          default(FALSE), not null
#

require 'spec_helper'

describe AttachedAsset do
  it { should belong_to(:attachable) }

  it { should allow_mass_assignment_of(:file) }
  it { should allow_mass_assignment_of(:asset_type) }
  it { should allow_mass_assignment_of(:direct_upload_url) }

  it { should_not allow_mass_assignment_of(:id) }
  it { should_not allow_mass_assignment_of(:file_file_name) }
  it { should_not allow_mass_assignment_of(:file_content_type) }
  it { should_not allow_mass_assignment_of(:file_file_size) }
  it { should_not allow_mass_assignment_of(:file_updated_at) }
  it { should_not allow_mass_assignment_of(:attachable_id) }
  it { should_not allow_mass_assignment_of(:attachable_type) }
  it { should_not allow_mass_assignment_of(:created_by_id) }
  it { should_not allow_mass_assignment_of(:updated_by_id) }
  it { should_not allow_mass_assignment_of(:created_at) }
  it { should_not allow_mass_assignment_of(:updated_at) }
  it { should_not allow_mass_assignment_of(:active) }
  it { should_not allow_mass_assignment_of(:processed) }

  describe "#activate" do
    let(:attached_asset) { FactoryGirl.build(:attached_asset, active: false) }

    it "should return the active value as true" do
      attached_asset.activate!
      attached_asset.reload
      attached_asset.active.should be_true
    end
  end

  describe "#deactivate" do
    let(:attached_asset) { FactoryGirl.build(:attached_asset, active: false) }

    it "should return the active value as false" do
      attached_asset.deactivate!
      attached_asset.reload
      attached_asset.active.should be_false
    end
  end
end
