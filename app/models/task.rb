# == Schema Information
#
# Table name: tasks
#
#  id              :integer          not null, primary key
#  event_id        :integer
#  title           :string(255)
#  due_at          :datetime
#  completed       :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  created_by_id   :integer
#  updated_by_id   :integer
#  active          :boolean          default(TRUE)
#  company_user_id :integer
#

class Task < ActiveRecord::Base
  track_who_does_it

  belongs_to :event
  belongs_to :company_user
  attr_accessible :completed, :due_at, :title, :company_user_id, :event_id
  has_many :comments, :as => :commentable, order: 'comments.created_at ASC'

  validates_datetime :due_at, allow_nil: true, allow_blank: true

  delegate :full_name, to: :user, prefix: true, allow_nil: true
  delegate :campaign_id, :company_id, to: :event, allow_nil: true

  validates :title, presence: true
  validates :company_user_id, numericality: true, if: :company_user_id
  validates :event_id, presence: true, numericality: true

  scope :by_companies, lambda{|companies| where(events: {company_id: companies}).joins(:event) }

  searchable do
    integer :id
    text :title
    string :title

    integer :company_user_id
    integer :event_id
    integer :company_id
    integer :campaign_id
    time :due_at
    time :last_activity

    string :user_name do
      company_user.try(:full_name)
    end

    boolean :completed

    string :status, multiple: true do
      status = []
      status.push active? ? 'Active' : 'Inactive'
      status.push completed? ? 'Completed' : 'Incomplete'
      status
    end
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def last_activity
    self.updated_at
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      ss = solr_search do

        with(:company_id, params[:company_id])
        with :company_user_id, params[:company_user_id] if params.has_key?(:company_user_id)
        with :event_id, params[:event_id] if params.has_key?(:event_id) and params[:event_id]

        # Handles the cases from the autocomplete
        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'task'
            with :id, value
          when 'campaign'
            with :campaign_id, value
          when 'companyuser'
            with :company_user_id, value
          when 'team'
            with :company_user_id, CompanyUser.joins(:teams).where(teams: {id: value}).map(&:id)
          end
        end

        if params[:start_date].present? and params[:end_date].present?
          d1 = Timeliness.parse(params[:start_date], zone: :current).beginning_of_day
          d2 = Timeliness.parse(params[:end_date], zone: :current).end_of_day
          with :due_at, d1..d2
        elsif params[:start_date].present?
          d = Timeliness.parse(params[:start_date], zone: :current)
          with :due_at, d.beginning_of_day..d.end_of_day
        end

        order_by(params[:sorting] || :due_at, params[:sorting_dir] || :asc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end
  end
end
