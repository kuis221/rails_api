# == Schema Information
#
# Table name: brand_ambassadors_visits
#
#  id              :integer          not null, primary key
#  company_id      :integer
#  company_user_id :integer
#  start_date      :date
#  end_date        :date
#  active          :boolean          default(TRUE)
#  created_at      :datetime
#  updated_at      :datetime
#  description     :text
#  visit_type      :string(255)
#  brand_id        :integer
#  area_id         :integer
#  city            :string(255)
#

class BrandAmbassadors::Visit < ActiveRecord::Base
  self.table_name = 'brand_ambassadors_visits'

  belongs_to :company_user
  belongs_to :company
  belongs_to :campaign
  belongs_to :area

  has_many :events, inverse_of: :visit

  delegate :name, to: :area, allow_nil: true, prefix: true
  delegate :name, to: :campaign, allow_nil: true, prefix: true

  scoped_to_company

  scope :active, ->{ where(active: true) }
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

  VISIT_TYPE_OPTIONS = {"Brand Program" => "brand_program",
                        "PTO" => "pto",
                        "Market Visit" => "market_visit",
                        "Local Market Request" => "local_market_request"}

  before_validation { self.city = nil if self.city == '' }

  validates :company_user, presence: true
  validates :company, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true,
      date: { on_or_after: :start_date, message: 'must be after' }
  validates :visit_type, presence: true
  validates :campaign, presence: true

  searchable if: :active do
    integer :id, stored: true
    integer :company_id
    integer :company_user_id
    integer :place_ids, multiple: true do
      events.pluck(:place_id)
    end
    integer :location, multiple: true do
      events.joins(place: :locations).pluck('DISTINCT(locations.id)')
    end
    date :start_date, stored: true
    date :end_date, stored: true

    string :visit_type
    integer :campaign_id
    integer :area_id
    string :city
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def visit_type_name
    BrandAmbassadors::Visit::VISIT_TYPE_OPTIONS.detect{|k,v| v == visit_type }.try(:[], 0) if visit_type
  end

  def self.do_search(params, include_facets=false)
    solr_search do
      with :company_id, params[:company_id]
      with :place_ids, params[:place] if params.has_key?(:place) and params[:place].present?

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

      with :area_id, params[:area] if params.has_key?(:area) and params[:area].present?
      with :campaign_id, params[:campaign] if params.has_key?(:campaign) and params[:campaign].present?
      with :city, params[:city] if params.has_key?(:city) and params[:city].present?

      if params[:start] && params[:end]
        start_date = DateTime.strptime(params[:start],'%Q')
        end_date = DateTime.strptime(params[:end],'%Q')
        params[:start_date] = start_date.to_s(:slashes)
        params[:end_date] = end_date.to_s(:slashes)
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
        when 'campaign'
          with :campaign_id, value
        when 'company_user'
          with :company_user_id, value
        when 'place'
          with :place_ids, value
        when 'venue'
          with :place_ids, Venue.find(value).place_id
        when 'area'
          with :area_id, value
        end
      end

      order_by(params[:sorting] || :start_date , params[:sorting_dir] || :asc)
      paginate page: (params[:page] || 1), per_page: (params[:per_page] || 30)
    end
  end
end
