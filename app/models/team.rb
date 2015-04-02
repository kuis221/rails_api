# == Schema Information
#
# Table name: teams
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  active        :boolean          default(TRUE)
#  company_id    :integer
#

class Team < ActiveRecord::Base
  include GoalableModel

  # Created_by_id and updated_by_id fields
  track_who_does_it

  scoped_to_company

  # Defines the method do_search
  include SolrSearchable

  validates :name, presence: true
  validates :company_id, presence: true, numericality: true

  # Teams-Users relationship
  has_many :memberships, as: :memberable
  has_many :users, class_name: 'CompanyUser', source: :company_user, through: :memberships,
                   after_add: :reindex_user, after_remove: :reindex_user

  has_many :teamings
  has_many :campaigns, through: :teamings, source: :teamable, source_type: 'Campaign'

  scope :active, -> { where(active: true) }

  scope :with_users, joins(:users).group('teams.id')
  scope :with_user, ->(company_user) { joins(:users).where(company_users: { id: company_user }).group('teams.id')  }
  scope :with_active_users, ->(companies) { joins(:users).where(company_users: { active: true, company_id: companies }).group('teams.id') }

  scope :accessible_by_user, ->(user) { in_company(user.company_id) }

  searchable do
    integer :id

    text :name, stored: true

    string :name
    string :status

    boolean :active

    integer :company_id

    integer :user_ids, multiple: true

    integer :campaign_ids, multiple: true do
      campaigns.map(&:id)
    end
    string :campaigns, multiple: true, references: Campaign do
      campaigns.map { |c| c.id.to_s + '||' + c.name }
    end
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

  def reindex_user(user)
    Sunspot.index(user)
  end

  class << self
    def searchable_params
      [campaign: [], user: [], team: [], status: []]
    end

    def report_fields
      {
        name:       { title: 'Name' }
      }
    end
  end

  def filter_subitems
    self.users.joins(:user).pluck('company_users.id, users.first_name || \' \' || users.last_name as name, \'user\'')
  end
end
