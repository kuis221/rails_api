# == Schema Information
#
# Table name: campaigns
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  aasm_state    :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :integer
#

class Campaign < ActiveRecord::Base
  include AASM

  # Created_by_id and updated_by_id fields
  track_who_does_it

  scoped_to_company

  attr_accessible :name, :description, :aasm_state, :team_ids, :brands_list
  attr_accessor :brands_list

  # Required fields
  validates :name, presence: true
  validates :company_id, presence: true, numericality: true

  # Campaigns-Teams relationship
  has_and_belongs_to_many :teams, :order => 'name ASC'

  # Campaigns-Brands relationship
  has_and_belongs_to_many :brands, :order => 'name ASC', :autosave => true

  # Campaigns-Users relationship
  has_many :campaigns_users
  has_many :users, through: :campaigns_users, :order => 'last_name ASC'

  # Campaigns-Events relationship
  has_many :events, :order => 'start_at ASC'

  scope :with_text, lambda{|text| where('campaigns.name ilike ? or campaigns.description ilike ? ', "%#{text}%", "%#{text}%") }

  aasm do
    state :inactive, :initial => true
    state :active
    state :closed

    event :activate do
      transitions :from => [:inactive, :closed], :to => :active
    end

    event :deactivate do
      transitions :from => :active, :to => :inactive
    end
  end

  def first_event
    events.order('start_at').first
  end

  def last_event
    events.order('start_at').last
  end


  def brands_list=(list)
    brands_names = list.split(',')
    existing_ids = self.brands.map(&:id)
    brands_names.each do |brand_name|
      brand = Brand.find_or_initialize_by_name(brand_name)
      self.brands << brand unless existing_ids.include?(brand.id)
    end
    brands.each{|brand| brand.mark_for_destruction unless brands_names.include?(brand.name) }
  end

  def brands_list
    brands.map(&:name).join ','
  end

end
