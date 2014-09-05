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

class DocumentFolder < ActiveRecord::Base
  belongs_to :parent, class_name: 'DocumentFolder'
  belongs_to :company
  belongs_to :folderable, polymorphic: true

  scoped_to_company

  scope :accessible_by_user, ->(company_user) { where(company_id: company_user.company_id) }

  has_many :documents, ->{ order('attached_assets.file_file_name ASC') },
      class_name: 'AttachedAsset', inverse_of: :folder, foreign_key: :folder_id

  has_many :brand_ambassadors_documents, ->{ order('attached_assets.file_file_name ASC') },
      class_name: 'BrandAmbassadors::Document', inverse_of: :folder, dependent: :destroy, foreign_key: :folder_id

  has_many :document_folders, ->{ order('document_folders.name ASC') }, foreign_key: :parent_id

  scope :active, ->{ where(active: true) }

  validates :name, presence: true,
        uniqueness: { scope: [:folderable_type, :folderable_id, :parent_id] }

  before_validation on: :create do
    self.folderable ||= Company.current
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end
end
