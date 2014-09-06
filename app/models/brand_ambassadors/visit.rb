# == Schema Information
#
# Table name: brand_ambassadors_visits
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  company_id      :integer
#  company_user_id :integer
#  start_date      :date
#  end_date        :date
#  active          :boolean          default(TRUE)
#  created_at      :datetime
#  updated_at      :datetime
#

class BrandAmbassadors::Visit < ActiveRecord::Base
  self.table_name = 'brand_ambassadors_visits'

  belongs_to :company_user
  belongs_to :company

  has_many :events, inverse_of: :visit

  scoped_to_company

  scope :accessible_by_user, ->(company_user) { where(company_id: company_user.company_id) }

  has_many :brand_ambassadors_documents, ->{ order('attached_assets.file_file_name ASC') },
      class_name: 'BrandAmbassadors::Document', as: :attachable, inverse_of: :attachable,
      dependent: :destroy do
    def root_children
      self.where(folder_id: nil)
    end
  end

  has_many :document_folders, ->{ order('document_folders.name ASC') },
      as: :folderable, inverse_of: :folderable do
    def root_children
      self.where(parent_id: nil)
    end
  end

  validates :name, presence: true
  validates :company_user, presence: true
  validates :company, presence: true

  validates :start_date, presence: true
  validates :end_date, presence: true,
      date: { on_or_after: :start_date, message: 'must be after' }

  searchable do
    integer :id, stored: true
    integer :company_id
    integer :company_user_id
    integer :place_ids, multiple: true do
      events.pluck(:place_id)
    end
    integer :location, multiple: true do
      events.joins(place: :locations).pluck('DISTINCT(locations.id)')
    end
    integer :campaign_ids, multiple: true do
      events.pluck(:campaign_id)
    end
    boolean :active
    date :start_date, stored: true
    date :end_date, stored: true

    string :name

    string :status
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def status
    self.active? ? 'Active' : 'Inactive'
  end

  def self.do_search(params, include_facets=false)
    solr_search do
      with :company_id, params[:company_id]
      with :status, params[:status] if params.has_key?(:status) and params[:status].present?
      with :place_ids, params[:place] if params.has_key?(:place) and params[:place].present?
      with :campaign_ids, params[:campaign] if params.has_key?(:campaign) and params[:campaign].present?

      if params[:start_date].present? and params[:end_date].present?
        d1 = Timeliness.parse(params[:start_date], zone: :current)
        d2 = Timeliness.parse(params[:end_date], zone: :current)
        any_of do
          with :start_date, d1..d2
          with :end_date, d1..d2
        end
      elsif params[:start_date].present?
        d = Timeliness.parse(params[:start_date], zone: :current)
        all_of do
          with(:start_date).less_than(d+1.day)
          with(:end_date).greater_than(d-1.day)
        end
      end

      if (params.has_key?(:user) && params[:user].present?) || (params.has_key?(:team) && params[:team].present?)
        user_ids = params[:user] || []
        user_ids += Team.where(id: params[:team]).joins(:users).pluck('company_users.id') if params.has_key?(:team) && params[:team].any?

        with :company_user_id, user_ids.uniq
      end

      if params[:area].present?
        any_of do
          with :place_ids, Area.where(id: params[:area]).joins(:places).where(places: {is_location: false}).pluck('places.id').uniq + [0]
          with :location, Area.where(id: params[:area]).map{|a| a.locations.map(&:id) }.flatten + [0]
        end
      end

      if params.has_key?(:brand) and params[:brand].present?
        campaing_ids = Campaign.joins(:brands).where(brands: {id: params[:brand]}, company_id: params[:company_id]).pluck('DISTINCT(campaigns.id)')
        with :campaign_ids, campaing_ids + [0]
      end

      if params[:start_date].present? and params[:end_date].present?
        d1 = Timeliness.parse(params[:start_date], zone: 'UTC').to_date
        d2 = Timeliness.parse(params[:end_date], zone: 'UTC').to_date
        any_of do
          with :start_date, d1..d2
          with :end_date, d1..d2
        end
      elsif params[:start_date].present?
        d = Timeliness.parse(params[:start_date], zone: 'UTC').to_date
        all_of do
          with(:start_date).less_than_or_equal_to(d)
          with(:end_date).greater_than_or_equal_to(d.beginning_of_day)
        end
      end

      if params.has_key?(:q) and params[:q].present?
        (attribute, value) = params[:q].split(',')
        case attribute
        when 'brand'
          campaigns = Campaign.select('campaigns.id').joins(:brands).where(brands: {id: value}).pluck('campaigns.id')
          campaigns = '-1' if campaigns.empty?
          with :campaign_ids, campaigns
        when 'campaign'
          with :campaign_ids, value
        when 'company_user'
          with :company_user_id, value
        when 'place'
          with :place_ids, value
        when 'venue'
          with :place_ids, Venue.find(value).place_id
        when 'area'
          any_of do
            with :place_ids, Area.where(id: value).joins(:places).where(places: {is_location: false}).pluck('places.id').uniq + [0]
            with :location, Area.find(value).locations.map(&:id) + [0]
          end
        end
      end

      order_by(params[:sorting] || :start_date , params[:sorting_dir] || :asc)
      paginate page: (params[:page] || 1), per_page: (params[:per_page] || 30)
    end
  end
end
