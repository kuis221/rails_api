# == Schema Information
#
# Table name: tasks
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  title         :string(255)
#  due_at        :datetime
#  user_id       :integer
#  completed     :boolean          default(FALSE)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :integer
#  updated_by_id :integer
#  active        :boolean          default(TRUE)
#

class Task < ActiveRecord::Base
  track_who_does_it

  belongs_to :event
  belongs_to :user
  attr_accessible :completed, :due_at, :title, :user_id, :event_id
  has_many :comments, :as => :commentable

  validates_datetime :due_at, allow_nil: true, allow_blank: true

  delegate :full_name, to: :user, prefix: true, allow_nil: true

  validates :title, presence: true
  validates :user_id, numericality: true, if: :user_id
  validates :event_id, presence: true, numericality: true

  scope :by_users, lambda{|users| where(user_id: users) }
  scope :by_teams, lambda{|teams| where(user_id: TeamsUser.select('user_id').where(team_id: teams).map(&:user_id)) }
  scope :by_companies, lambda{|companies| where(events: {company_id: companies}).joins(:event) }
  scope :by_period, lambda{|start_date, end_date| where("due_at >= ? AND due_at <= ?", Timeliness.parse(start_date), Timeliness.parse(end_date.empty? ? start_date : end_date).end_of_day) unless start_date.nil? or start_date.empty? }
  scope :with_text, lambda{|text| where('tasks.title ilike ? or tu.first_name ilike ? or tu.last_name ilike ?', "%#{text}%", "%#{text}%", "%#{text}%").joins('LEFT JOIN "users" "tu" ON "tu"."id" = "tasks"."user_id"') }

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end
end
