class Activity < ActiveRecord::Base
  attr_accessible :end_date, :name, :start_date, :start_date_date, :end_date_date, :start_date_time, :end_date_time


  before_validation   :parse_start_end
  after_initialize :set_event_dates
  attr_accessor       :start_date_date, :start_date_time, :end_date_date, :end_date_time

  validate :valid_start_end_dates

  scope :after_date, proc { |date| where('start_date >= ?', date) }
  scope :before_date, proc { |date| where('start_date <= ?', date) }

  private

    def valid_start_end_dates
      if end_date <= start_date
        errors.add(:end_date_date, 'have to be after the start date')
      end
      true
    end

    def parse_start_end
      parts = self.start_date_date.split("/")
      self.start_date = Time.zone.parse([[parts[1],parts[0],parts[2]].join('/'), self.start_date_time].join(' '))
      parts = self.end_date_date.split("/")
      self.end_date = Time.zone.parse([[parts[1],parts[0],parts[2]].join('/'), self.end_date_time].join(' '))
    end

    def set_event_dates # get dates
      if new_record?
        self.start_date_time ||= '12:00 PM'
        self.end_date_time ||= '01:00 PM'
      else
        self.start_date_date = self.start_date.to_s(:slashes)   unless self.start_date.blank?
        self.start_date_time = self.start_date.to_s(:time_only) unless self.start_date.blank?
        self.end_date_date   = self.end_date.to_s(:slashes)     unless self.end_date.blank?
        self.end_date_time   = self.end_date.to_s(:time_only)   unless self.end_date.blank?
      end
    end
end
