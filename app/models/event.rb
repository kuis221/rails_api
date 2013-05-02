class Event < ActiveRecord::Base
  belongs_to :campaign
  has_and_belongs_to_many :users


  attr_accessible :end_date, :end_time, :start_date, :start_time, :campaign_id, :event_ids, :user_ids

  scoped_to_company

  validates :campaign_id, presence: true, numericality: true
  validates :start_at, presence: true
  validates :end_at, presence: true
  validate :end_after_start, if: :has_start_and_end?


  attr_accessor       :start_date, :start_time, :end_date, :end_time

  after_initialize :set_start_end_dates
  before_validation :parse_start_end

  delegate :name, to: :campaign, prefix: true, allow_nil: true

  private

    def has_start_and_end?
      !(start_at.nil? || end_at.nil?)
    end

    def end_after_start
      errors.add(:end_at, "#{start_at} | #{end_at} | #{hours} must be after the start time.") if start_at > end_at
    end

    def parse_start_end
      if self.start_date
        parts = self.start_date.split("/")
        self.start_at = Time.zone.parse([[parts[1],parts[0],parts[2]].join('/'), self.start_time].join(' '))
      end
      if self.end_date
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
