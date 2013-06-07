# == Schema Information
#
# Table name: date_items
#
#  id                :integer          not null, primary key
#  date_range_id     :integer
#  start_date        :date
#  end_date          :date
#  recurrence        :boolean          default(FALSE)
#  recurrence_type   :string(255)
#  recurrence_period :integer
#  recurrence_days   :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class DateItem < ActiveRecord::Base
  RECURRENCE_TYPES = %w(daily weekly monthly yearly)

  attr_accessible :start_date, :end_date, :recurrence, :recurrence_days, :recurrence_period, :recurrence_type

  validates :date_range_id, presence: true, numericality: true

  belongs_to :date_range

  validates_date :start_date
  validates_date :end_date, on_or_after: :start_date, allow_nil: true


  validates :recurrence_type, :inclusion => { :in => RECURRENCE_TYPES,
    :message => "%{value} is not valid" }


  validate :validate_days


  serialize :recurrence_days

  def label
    description = describe_dates
    if recurrence
      description += ' ' + describe_recurrence_period
    end
    description.strip!
    # Make sure the first letter is in upper case without changing the others
    description = description.slice(0,1).capitalize + description.slice(1..-1) unless description.empty?
    description
  end

  private
    def describe_dates
      if start_date and end_date
        "From #{start_date} to #{end_date}"
      elsif start_date
        "On #{start_date}"
      else
        ""
      end
    end

    def describe_recurrence_period
      description = ''
      if recurrence_type.present?
        description = 'every ' + I18n.translate("recurrence.#{recurrence_type}", count: recurrence_period)
      end

      days = recurrence_days
      if days.present? and !days.empty?
        days = [days] unless days.is_a?(Array)
        days = days.compact.reject{|d| d.nil? || d == '' }.map(&:capitalize)
        description += ' on ' + days.to_sentence(last_word_connector: ' and ') unless days.empty?
      end
      description
    end

    def validate_days
      return if recurrence_days.nil?
      if invalid_days = (recurrence_days - Date::DAYNAMES.map(&:downcase))
        invalid_days.each do |day|
          errors.add(:recurrence_days,  "#{day} is not a valid weekday")
        end
      end
    end
end
