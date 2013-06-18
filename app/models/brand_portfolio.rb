# == Schema Information
#
# Table name: brand_portfolios
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  active        :boolean          default(TRUE)
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
    integer :id

    text :name
    text :description

    string :name
    string :description

    boolean :active

    integer :company_id

    integer :brand_ids, multiple: true
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      ss = solr_search do

        with(:company_id, params[:company_id])
        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'brandportfolio'
            with :id, value
          else
            with "#{attribute}_ids", value
          end
        end

        order_by(params[:sorting] || :name, params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end
  end
end
