# == Schema Information
#
# Table name: day_parts
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  active        :boolean          default(TRUE)
#  company_id    :integer
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class DayPart < ActiveRecord::Base
  include GoalableModel
  # Created_by_id and updated_by_id fields
  track_who_does_it

  scoped_to_company

  validates :name, presence: true, uniqueness: { scope: :company_id }
  validates :company_id, presence: true

  has_many :day_items

  searchable do
    integer :id

    text :name, stored: true

    string :name
    string :status

    boolean :active

    integer :company_id
  end

  def status
    self.active? ? 'Active' : 'Inactive'
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def day_part_created_by
    CompanyUser.find(self.created_by_id).full_name if self.created_by_id.present?
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets = false)
      ss = solr_search do
        with(:company_id, params[:company_id])
        with(:status, params[:status]) if params.key?(:status) && params[:status].present?
        with(:id, params[:day_part]) if params.key?(:day_part) && params[:day_part].present?


        facet :status if include_facets

        order_by(params[:sorting] || :name, params[:sorting_dir] || :asc)
        paginate page: (params[:page] || 1), per_page: (params[:per_page] || 30)
      end
    end

    def searchable_params
      [day_part: [], status: []]
    end

    def report_fields
      {
        name: { title: 'Name' }
      }
    end
  end
end
