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
#  area_id         :integer
#  city            :string(255)
#  campaign_id     :integer
#

class BrandAmbassadors::Visit < ActiveRecord::Base
  self.table_name = 'brand_ambassadors_visits'

  belongs_to :company_user
  belongs_to :company
  belongs_to :campaign
  belongs_to :area

  delegate :name, to: :area, allow_nil: true, prefix: true
  delegate :name, :color, to: :campaign, allow_nil: true, prefix: true

  scoped_to_company

  scope :active, -> { where(active: true) }
  scope :accessible_by_user, ->(company_user) { where(company_id: company_user.company_id) }

  has_many :brand_ambassadors_documents, -> { order('attached_assets.file_file_name ASC') },
           class_name: 'BrandAmbassadors::Document', as: :attachable, inverse_of: :attachable,
           dependent: :destroy do
    def root_children
      where(folder_id: nil)
    end
  end

  has_many :document_folders, -> { order('document_folders.name ASC') },
           as: :folderable, inverse_of: :folderable do
    def root_children
      where(parent_id: nil)
    end
  end

  before_validation { self.city = nil if city == '' }

  validates :company_user, presence: true
  validates :company, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true,
                       date: { on_or_after: :start_date, message: 'must be after' }
  validates :visit_type, presence: true
  validates :campaign, presence: true

  validate :valid_campaign?

  searchable if: :active do
    integer :id, stored: true
    integer :company_id
    integer :company_user_id
    join(:location, target: Area, type: :integer, join: { from: :id, to: :area_id }, as: 'location_ids_im')
    date :start_date, stored: true
    date :end_date, stored: true

    string :visit_type
    integer :campaign_id
    integer :area_id do
      area_id.nil? ? -1 : area_id
    end
    string :city
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

  def self.do_search(params, _include_facets = false)
    solr_search(include: [:campaign, :area, company_user: :user]) do
      with :company_id, params[:company_id]

      company_user = params[:current_company_user]
      if company_user.present?
        current_company = company_user.company
        unless company_user.role.is_admin?
          with :campaign_id, company_user.accessible_campaign_ids + [0]
          adjust_solr_params do |params|
            params[:fq] << "area_id_i:\\-1 OR _query_:\"{!join from=id_i to=area_id_i}location_ids_im:(#{(company_user.accessible_locations + [0]).join(' OR ')})\""
          end
        end
      end

      if params[:start] && params[:end]
        start_date = DateTime.strptime(params[:start], '%Q')
        end_date = DateTime.strptime(params[:end], '%Q')
        params[:start_date] = start_date.to_s(:slashes)
        params[:end_date] = end_date.to_s(:slashes)
      end

      if params[:start_date].present? && params[:end_date].present?
        params[:start_date] = Array(params[:start_date])
        params[:end_date] = Array(params[:end_date])
        any_of do
          params[:start_date].each_with_index do |start, index|
            d1 = Timeliness.parse(start, zone: :current)
            d2 = Timeliness.parse(params[:end_date][index], zone: :current)
            if d1 == d2
              all_of do
                with(:start_date).less_than(d1 + 1.day)
                with(:end_date).greater_than(d1 - 1.day)
              end
            else
              with :start_date, d1..d2
              with :end_date, d1..d2
            end
          end
        end
      elsif params[:start_date].present?
        d = Timeliness.parse(params[:start_date][0], zone: :current)
        all_of do
          with(:start_date).less_than(d + 1.day)
          with(:end_date).greater_than(d - 1.day)
        end
      end

      if (params.key?(:user) && params[:user].present?) || (params.key?(:team) && params[:team].present?)
        user_ids = params[:user] || []
        user_ids += Team.where(id: params[:team]).joins(:users).pluck('company_users.id') if params.key?(:team) && params[:team].any?

        with :company_user_id, user_ids.uniq
      end

      with :area_id, params[:area] if params.key?(:area) && params[:area].present?
      with :campaign_id, params[:campaign] if params.key?(:campaign) && params[:campaign].present?
      with :city, params[:city] if params.key?(:city) && params[:city].present?

      if params.key?(:q) && params[:q].present?
        (attribute, value) = params[:q].split(',')
        case attribute
        when 'campaign'
          with :campaign_id, value
        when 'company_user'
          with :company_user_id, value
        when 'area'
          with :area_id, value
        end
      end

      order_by(params[:sorting] || :start_date, params[:sorting_dir] || :asc)
      paginate page: (params[:page] || 1), per_page: (params[:per_page] || 30)
    end
  end

  protected

  def valid_campaign?
    return unless campaign.present? && campaign.company_id != company_id
    errors.add :campaign_id, :invalid
  end
end
