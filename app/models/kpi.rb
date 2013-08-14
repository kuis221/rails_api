# == Schema Information
#
# Table name: kpis
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  description       :text
#  kpi_type          :string(255)
#  capture_mechanism :string(255)
#  company_id        :integer
#  created_by_id     :integer
#  updated_by_id     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  module            :string(255)      default("custom"), not null
#

class Kpi < ActiveRecord::Base
  track_who_does_it

  scoped_to_company

  CUSTOM_TYPE_OPTIONS = {"number"     => ["integer", "decimal", "currency"],
                         "count"      => ["radio", "dropdown", "checkbox"],
                         "percentage" => ["integer", "decimal"]}

  OUT_BOX_TYPE_OPTIONS = ['promo_hours', 'events_count', 'photos', 'videos']

  GOAL_ONLY_TYPE_OPTIONS = OUT_BOX_TYPE_OPTIONS + ['number']

  COMPLETE_TYPE_OPTIONS = CUSTOM_TYPE_OPTIONS.keys + OUT_BOX_TYPE_OPTIONS

  attr_accessible :name, :description, :kpi_type, :capture_mechanism, :kpis_segments_attributes, :goals_attributes

  validates :name, presence: true, uniqueness: {scope: :company_id}
  validates :company_id, numericality: true, allow_nil: true

  validates :kpi_type, :inclusion => {:in => COMPLETE_TYPE_OPTIONS, :message => "%{value} is not valid"}

  # Campaigns-KPIs relationship
  has_and_belongs_to_many :campaigns

  # KPIs-Segments relationship
  has_many :kpis_segments, dependent: :destroy, order: :id

  # KPIs-Goals relationship
  has_many :goals

  accepts_nested_attributes_for :kpis_segments, reject_if: lambda { |x| x[:text].blank? && x[:id].blank? }, allow_destroy: true
  accepts_nested_attributes_for :goals

  scope :global_and_custom, lambda{|company| where('company_id is null or company_id=?', company).order('company_id DESC, id ASC') }
  scope :in_module, lambda{ where('module is not null and module != \'\'') }

  after_save :sync_segments_and_goals

  searchable do
    text :name, stored: true
    string :name
    integer :company_id
  end

  def out_of_the_box?
    self.module != 'custom'
  end

  def sync_segments_and_goals
    unless self.out_of_the_box?
      if GOAL_ONLY_TYPE_OPTIONS.include?(self.kpi_type)
        self.kpis_segments.delete_all
      else
        self.goals.where(kpis_segment_id: nil).delete_all
      end
    end
  end

  class << self
    def impressions
      @impressions ||= where(company_id: nil).find_by_name_and_module('Impressions', 'consumer_reach')
    end

    def interactions
      @interactions ||= where(company_id: nil).find_by_name_and_module('Interactions', 'consumer_reach')
    end

    def samples
      @samples ||= where(company_id: nil).find_by_name_and_module('Samples', 'consumer_reach')
    end

    def cost
      @cost ||= where(company_id: nil).find_by_name_and_module('Cost', 'expenses')
    end

    def gender
      @gender ||= where(company_id: nil).find_by_name_and_module('Gender', 'demographics')
    end

    def age
      @age ||= where(company_id: nil).find_by_name_and_module('Age', 'demographics')
    end

    def ethnicity
      @ethnicity ||= where(company_id: nil).find_by_name_and_module('Ethnicity/Race', 'demographics')
    end

    def photos
      @photos ||= where(company_id: nil).find_by_name_and_module('Photos', 'photos')
    end
  end

end
