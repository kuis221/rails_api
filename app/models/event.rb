# == Schema Information
#
# Table name: events
#
#  id            :integer          not null, primary key
#  campaign_id   :integer
#  company_id    :integer
#  start_at      :datetime
#  end_at        :datetime
#  aasm_state    :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  active        :boolean          default(TRUE)
#  place_id      :integer
#

class Event < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :place, autosave: true
  has_and_belongs_to_many :users
  has_many :tasks, dependent: :destroy
  has_many :documents, :as => :documentable

  attr_accessible :end_date, :end_time, :start_date, :start_time, :campaign_id, :event_ids, :user_ids, :file, :place_reference, :brands_list

  # Events-Brands relationship
  has_and_belongs_to_many :brands, :order => 'name ASC', :autosave => true

  scoped_to_company

  attr_accessor :place_reference
  attr_accessor :brands_list

  scope :by_period, lambda{|start_date, end_date| where("start_at >= ? AND start_at <= ?", Timeliness.parse(start_date), Timeliness.parse(end_date.empty? ? start_date : end_date).end_of_day) unless start_date.nil? or start_date.empty? }
  scope :with_text, lambda{|text| where('epj.name ilike ? or ecj.name ilike ?', "%#{text}%", "%#{text}%").joins('LEFT JOIN "campaigns" "ecj" ON "ecj"."id" = "events"."campaign_id" LEFT JOIN "places" "epj" ON "epj"."id" = "events"."place_id"') }
  scope :by_campaigns, lambda{|campaigns| where(campaign_id: campaigns) }

  track_who_does_it

  #validates_attachment_content_type :file, :content_type => ['image/jpeg', 'image/png']
  validates :campaign_id, presence: true, numericality: true
  validates :start_at, presence: true
  validates :end_at, presence: true

  validates_datetime :start_at
  validates_datetime :end_at, :on_or_after => :start_at

  attr_accessor :start_date, :start_time, :end_date, :end_time

  after_initialize :set_start_end_dates
  before_validation :parse_start_end
  after_validation :delegate_errors

  delegate :name, to: :campaign, prefix: true, allow_nil: true
  delegate :name,:latitude,:longitude,:formatted_address, to: :place, prefix: true, allow_nil: true


  searchable do
    boolean :active
    time :start_at, :trie => true
    time :end_at, :trie => true
    string :status
    string :start_time

    integer :company_id

    integer :campaign_id
    string :campaign do
      campaign_id.to_s + '||' + campaign_name if campaign_id
    end
    text :campaign_txt do
      campaign_name
    end
    string :campaign_name

    integer :place_id
    string :place do
      place_id.to_s + '||' + place_name if place_id
    end
    text :place_txt do
      place_name
    end
    string :place_name

    integer :user_ids, multiple: true do
      users.map(&:id)
    end

    string :users, multiple: true, references: User do
      users.map{|u| u.id.to_s + '||' + u.name}
    end

    string :brands, multiple: true, references: Brand do
      brands.map{|b| b.id.to_s + '||' + b.name}
    end

    string :brand_ids, multiple: true, references: Brand do
      brands.map(&:id)
    end
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def place_reference=(value)
    if value and value != self.place_reference and !value.nil? and !value.empty?
      reference, place_id = value.split('||')
      self.place = Place.find_or_initialize_by_place_id(place_id, {reference: reference}) if value
    end
  end

  def place_reference
    self.place.name if self.place
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

  def status
    self.active? ? 'Active' : 'Inactive'
  end

  private

    # Copy some errors to the attributes used on the forms so the user
    # can see them
    def delegate_errors
      errors[:start_at].each{|e| errors.add(:start_date, e) }
      errors[:end_at].each{|e| errors.add(:end_date, e) }
      place.errors.full_messages.each{|e| errors.add(:place_reference, e) } if place
    end

    def parse_start_end
      unless self.start_date.nil? or self.start_date.empty?
        parts = self.start_date.split("/")
        self.start_at = Time.zone.parse([[parts[1],parts[0],parts[2]].join('/'), self.start_time].join(' '))
      end
      unless self.end_date.nil? or self.end_date.empty?
        parts = self.end_date.split("/")
        self.end_at = Time.zone.parse([[parts[1],parts[0],parts[2]].join('/'), self.end_time].join(' '))
      end
    end

    # Sets the values for start_date, start_time, end_date and end_time when from start_at and end_at
    def set_start_end_dates
      if new_record?
        self.start_time ||= '12:00 PM'
        self.end_time ||= '01:00 PM'
      else
        self.start_date = self.start_at.to_s(:slashes)   unless self.start_at.blank?
        self.start_time = self.start_at.to_s(:time_only) unless self.start_at.blank?
        self.end_date   = self.end_at.to_s(:slashes)     unless self.end_at.blank?
        self.end_time   = self.end_at.to_s(:time_only)   unless self.end_at.blank?
      end
    end


end
