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

  attr_accessible :name, :description, :user_ids, :campaigns_ids

  validates :name, presence: true
  validates :company_id, presence: true, numericality: true

  # Teams-Users relationship
  has_many :memberships, :as => :memberable
  has_many :users, :class_name => 'CompanyUser', source: :company_user, :through => :memberships,
                   :after_add => :reindex_user, :after_remove => :reindex_user


  has_many :teamings
  has_many :campaigns, through: :teamings, :source => :teamable, :source_type => 'Campaign'

  after_save :update_events

  scope :active, where(:active => true)

  scope :with_users, joins(:users).group('teams.id')
  scope :with_active_users, lambda{|companies| joins(:users).where(:company_users => {:active => true, :company_id => companies}).group('teams.id') }

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
      campaigns.map{|c| c.id.to_s + '||' + c.name}
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
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      ss = solr_search do

        with(:company_id, params[:company_id])
        with(:campaign_ids, params[:campaign]) if params.has_key?(:campaign) and params[:campaign].present?
        with(:status, params[:status]) if params.has_key?(:status) and params[:status].present?
        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'team'
            with :id, value
          when 'company_user'
            with :user_ids, value
          else
            with "#{attribute}_ids", value
          end
        end

        if include_facets
          facet :campaigns
          facet :status
        end

        order_by(params[:sorting] || :name, params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end
  end

  private
    def update_events
      if name_changed?
        Resque.enqueue(TeamIndexer, self.id)
      end
    end
end
