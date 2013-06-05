# == Schema Information
#
# Table name: brand_portfolios
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  active        :boolean
#  company_id    :integer
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  description   :text
#

class BrandPortfolio < ActiveRecord::Base
  # Created_by_id and updated_by_id fields
  track_who_does_it

  scoped_to_company

  attr_accessible :name, :description

  validates :name, presence: true, uniqueness: {scope: :company_id}
  validates :company_id, presence: true

  has_and_belongs_to_many :brands

  searchable do
    text :name_txt do
      name
    end
    text :description_txt do
      description
    end

    boolean :active

    string :name
    integer :company_id
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end
end
