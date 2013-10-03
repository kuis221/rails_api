# == Schema Information
#
# Table name: date_ranges
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

class DateRange < ActiveRecord::Base
  include GoalableModel
  # Created_by_id and updated_by_id fields
  track_who_does_it

  scoped_to_company

  validates :name, presence: true, uniqueness: {scope: :company_id}
  validates :company_id, presence: true

  has_many :date_items

  scope :active, where(:active => true)

  searchable do
    integer :id
    text :name, stored: true

    boolean :active

    string :name
    string :status
    integer :company_id
  end

  # Date ranges filters were removed from events list
  # def search_filters(solr_search_obj)
  #   date_items.each do |date|
  #     if date.start_date and date.end_date
  #       d1 = Timeliness.parse(date.start_date, zone: :current).beginning_of_day
  #       d2 = Timeliness.parse(date.end_date, zone: :current).end_of_day
  #       solr_search_obj.with :start_at, d1..d2
  #     elsif date.start_date
  #       d = Timeliness.parse(date.start_date, zone: :current)
  #       solr_search_obj.with :start_at, d.beginning_of_day..d.end_of_day
  #     end

  #     if date.recurrence
  #       if date.recurrence_days.any?
  #         solr_search_obj.with :day_names, date.recurrence_days
  #       end
  #     end
  #   end
  # end

  def status
    self.active? ? 'Active' : 'Inactive'
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
        with(:status,     params[:status]) unless params[:status].nil? || params[:status].empty?
        with(:company_id, params[:company_id])

        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          if attribute == 'date_range'
            with :id, value
          end
        end

        if include_facets
          facet :status
        end

        order_by(params[:sorting] || :name , params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end
  end
end
