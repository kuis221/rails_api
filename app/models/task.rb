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
  has_many :comments, :as => :commentable, order: 'comments.created_at ASC'

  after_save :create_notifications

  validates_datetime :due_at, allow_nil: true, allow_blank: true

  delegate :full_name, to: :company_user, prefix: :user, allow_nil: true
  delegate :campaign_id, :campaign_name, :place_id, :company_id, to: :event, allow_nil: true

  validates :title, presence: true
  validates :company_user_id, numericality: true, if: :company_user_id
  validates :event_id, presence: true, numericality: true

  scope :incomplete, lambda{ where(completed: false) }
  scope :active, lambda{ where(active: true) }
  scope :by_companies, lambda{|companies| where(events: {company_id: companies}).joins(:event) }
  scope :late, lambda{ where(['due_at is not null and due_at < ? and completed = ?', Date.today, false]) }
  scope :due_today, lambda{ where(['due_at BETWEEN ? and ? and completed = ?', Date.today, Date.tomorrow, false]) }
  scope :due_today_and_late, lambda{ where(['due_at is not null and due_at <= ? and completed = ?', Date.today.end_of_day, false]) }
  scope :assigned_to, lambda{|users| where(company_user_id: users) }

  searchable do
    integer :id
    text :name, stored: true do
      title
    end

    integer :company_user_id, references: CompanyUser
    integer :event_id
    integer :company_id

    integer :team_members, multiple: true do
      event.memberships.map(&:company_user_id) + event.teams.map{|t| t.memberships.map(&:company_user_id) }.flatten.uniq
    end

    integer :campaign_id

    time :due_at, :trie => true
    time :last_activity

    string :user_name do
      company_user.try(:full_name)
    end

    boolean :completed
    string :status do
      if event.active?
        active? ? 'Active' : 'Inactive'
      else
        'Inactive Event'
      end
    end

    string :statusm, multiple: true do
      status = []
      status.push active? ? 'Active' : 'Inactive'
      status.push assigned? ? 'Assigned' : 'Unassigned'
      status.push completed? ? 'Complete' : 'Incomplete'
      status
    end
  end

  def due_today?
    due_at.to_date <= Date.today && due_at.to_date >= Date.today unless due_at.nil?
  end

  def late?
    !completed? && due_at.to_date <= Date.yesterday unless due_at.nil?
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def assigned?
    self.company_user_id.present?
  end

  def last_activity
    self.updated_at
  end

  def statuses
    status = []
    status.push active? ? 'Active' : 'Inactive'
    status.push assigned? ? 'Assigned' : 'Unassigned'
    status.push completed? ? 'Complete' : 'Incomplete'
    status.push 'Late' if late?
    status.push 'Due' if due_today?
    status
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      ss = solr_search({include: [{:company_user => :user}, :event]}) do

        # Filter by user permissions
        company_user = params[:current_company_user]
        if company_user.present?
          unless company_user.role.is_admin?
            with(:campaign_id, company_user.accessible_campaign_ids + [0])
          end
        end

        with :id, params[:id] if params.has_key?(:id) and params[:id]
        with :company_id, params[:company_id]
        with :campaign_id, params[:campaign]  if params.has_key?(:campaign) and params[:campaign]
        with :company_user_id, params[:user] if params.has_key?(:user) and params[:user].present?
        with :event_id, params[:event_id] if params.has_key?(:event_id) and params[:event_id]
        with :team_members, params[:team_members] if params.has_key?(:team_members) and params[:team_members]

        with :company_user_id, CompanyUser.joins(:teams).where(teams: {id: params[:team]}).map(&:id) if params.has_key?(:team) and !params[:team].empty?
        without :company_user_id, params[:not_assigned_to] if params.has_key?(:not_assigned_to) and !params[:not_assigned_to].empty?

        if params.has_key?(:status) and params[:status]
          late = params[:status].delete('Late')
          with(:status, params[:status].uniq) unless params[:status].empty?

          params[:late] = true if late.present?
        end

        if params.has_key?(:task_status) and params[:task_status]
          late = params[:task_status].delete('Late')
          any_of do
            with :statusm, params[:task_status].uniq unless params[:task_status].empty?
            if late.present?
              all_of do
                with(:due_at).less_than(Time.zone.now)
                with(:completed, false)
              end
            end
          end
        end

        # Handles the cases from the autocomplete
        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'task'
            with :id, value
          when 'campaign'
            with :campaign_id, value
          when 'company_user'
            with :company_user_id, value
          when 'team'
            with :company_user_id, CompanyUser.select('company_users.id').joins(:teams).where(teams: {id: value}).map(&:id)
          end
        end

        if params[:late]
          with(:due_at).less_than(Time.zone.now)
          with :completed, false
        end

        if params[:start_date].present? and params[:end_date].present?
          d1 = Timeliness.parse(params[:start_date], zone: :current).beginning_of_day
          d2 = Timeliness.parse(params[:end_date], zone: :current).end_of_day
          with :due_at, d1..d2
        elsif params[:start_date].present?
          d = Timeliness.parse(params[:start_date], zone: :current)
          with :due_at, d.beginning_of_day..d.end_of_day
        end

        if include_facets
          facet :campaign_id
          facet :status do
            row(:late) do
              with(:statusm, 'Incomplete')
              with(:due_at).less_than(Date.yesterday.beginning_of_day)
            end
            row(:unassigned) do
              with(:statusm, 'Unassigned')
            end
            row(:assigned) do
              with(:statusm, 'Assigned')
            end
            row(:incomplete) do
              with(:statusm, 'Incomplete')
            end
            row(:complete) do
              with(:statusm, 'Complete')
            end
            row(:active) do
              with(:statusm, 'Active')
            end
            row(:inactive) do
              with(:statusm, 'Inactive')
            end
          end
          facet :company_user_id
        end

        order_by(params[:sorting] || :due_at, params[:sorting_dir] || :asc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end

    def report_fields
      {
        title:       { title: 'Title' },
        due_at:      { title: 'Start time' },
        active:      { title: 'Active State' },
        task_status: { title: 'Event Status' }
      }
    end

    def search_params_for_scope(scope, company_user)
      if scope == 'user'
        {user: [company_user.id]}
      elsif scope == 'teams'
        {team_members: [company_user.id], not_assigned_to: [company_user.id]}
      else
        {}
      end
    end
  end

  private
    def create_notifications
      if (id_changed? || company_user_id_changed?) && company_user_id.present?
        #New task with assigned user or assigning user to existing task
        Notification.new_task(company_user, self)
      # elsif id_changed? && company_user_id.nil?
      #   #New task without assigned user
      #   event.all_users.each do |user|
      #     Notification.new_task(user, self, true)
      #   end
      end
    end

end
