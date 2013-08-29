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

  OUT_BOX_TYPE_OPTIONS = ['promo_hours', 'events_count', 'photos', 'videos', 'surveys']

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

    def videos
      @videos ||= where(company_id: nil).find_by_name_and_module('Videos', 'videos')
    end

    def surveys
      @surveys ||= where(company_id: nil).find_by_name_and_module('Surveys', 'surveys')
    end
  end


  # This method is only used during the DB seed and tests
  def self.create_global_kpis
    Kpi.create({name: 'Promo Hours', kpi_type: 'promo_hours', description: 'Total duration of events', capture_mechanism: '', company_id: nil, 'module' => ''}, without_protection: true)
    Kpi.create({name: 'Events', kpi_type: 'events_count', description: 'Number of events executed', capture_mechanism: '', company_id: nil, 'module' => ''}, without_protection: true)
    Kpi.create({name: 'Impressions', kpi_type: 'number', description: 'Total number of consumers who come in contact with an event', capture_mechanism: 'integer', company_id: nil, 'module' => 'consumer_reach'}, without_protection: true)
    Kpi.create({name: 'Interactions', kpi_type: 'number', description: 'Total number of consumers who directly interact with an event', capture_mechanism: 'integer', company_id: nil, 'module' => 'consumer_reach'}, without_protection: true)
    Kpi.create({name: 'Samples', kpi_type: 'number', description: 'Number of consumers who try a product sample', capture_mechanism: 'integer', company_id: nil, 'module' => 'consumer_reach'}, without_protection: true)
    gender_kpi    = Kpi.create({name: 'Gender', kpi_type: 'percentage', description: 'Number of consumers who try a product sample', capture_mechanism: 'integer', company_id: nil, 'module' => 'demographics'}, without_protection: true)
    age_kpi       = Kpi.create({name: 'Age', kpi_type: 'percentage', description: 'Percentage of attendees who are within a certain age range', capture_mechanism: 'integer', company_id: nil, 'module' => 'demographics'}, without_protection: true)
    ethnicity_kpi = Kpi.create({name: 'Ethnicity/Race', kpi_type: 'percentage', description: 'Percentage of attendees who are of a certain ethnicity or race', capture_mechanism: 'integer', company_id: nil, 'module' => 'demographics'}, without_protection: true)
    Kpi.create({name: 'Cost', kpi_type: 'number', description: 'Total cost of an event', capture_mechanism: 'currency', company_id: nil, 'module' => 'expenses'}, without_protection: true)
    Kpi.create({name: 'Photos', kpi_type: 'photos', description: 'Total number of photos uploaded to an event', capture_mechanism: '', company_id: nil, 'module' => 'photos'}, without_protection: true)
    Kpi.create({name: 'Videos', kpi_type: 'videos', description: 'Total number of photos uploaded to an event', capture_mechanism: '', company_id: nil, 'module' => 'videos'}, without_protection: true)
    Kpi.create({name: 'Surveys', kpi_type: 'surveys', description: 'Total number of surveys completed for a campaign', capture_mechanism: 'integer', company_id: nil, 'module' => 'surveys'}, without_protection: true)
    Kpi.create({name: 'Competitive Analysis', kpi_type: 'number', description: 'Total number of competitive analyses created for a campaign', capture_mechanism: 'integer', company_id: nil, 'module' => 'competitive_analysis'}, without_protection: true)

    ['< 12', '12 – 17', '18 – 24', '25 – 34', '35 – 44', '45 – 54', '55 – 64', '65+'].each do |segment|
      age_kpi.kpis_segments.create(text: segment)
    end

    ['Female', 'Male'].each do |segment|
      gender_kpi.kpis_segments.create(text: segment)
    end

    ['Asian', 'Black / African American', 'Hispanic / Latino', 'Native American', 'White'].each do |segment|
      ethnicity_kpi.kpis_segments.create(text: segment)
    end
  end

end
