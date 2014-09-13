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
#  rating            :integer          default(0)
#  folder_id         :integer
#

class BrandAmbassadors::Document < ::AttachedAsset

  validates :file_file_name, presence: true, length: { maximum: 255 }

  default_scope -> { where(asset_type: 'ba_document') }

  scope :active, -> { where(active: true) }

  before_validation on: :create do
    self.asset_type ||= 'ba_document'
    self.attachable ||= Company.current
  end
end
