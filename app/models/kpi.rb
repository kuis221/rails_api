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
#  slug              :string(255)
#  module            :string(255)      default("custom"), not null
#

class Kpi < ActiveRecord::Base
  track_who_does_it

  extend FriendlyId
  friendly_id :name, use: :scoped, scope: :company_id

  scoped_to_company

  CUSTOM_TYPE_OPTIONS = {"number"     => ["integer", "decimal", "currency"],
                         "count"      => ["radio", "dropdown", "checkbox"],
                         "percentage" => ["integer", "decimal"]}

  OUT_BOX_TYPE_OPTIONS = ['promo_hours', 'events_count', 'photos', 'videos']

  COMPLETE_TYPE_OPTIONS = CUSTOM_TYPE_OPTIONS.keys + OUT_BOX_TYPE_OPTIONS

  attr_accessible :name, :description, :kpi_type, :capture_mechanism, :kpis_segments_attributes, :goals_attributes

  validates :name, presence: true, uniqueness: {scope: :company_id}
  validates :company_id, numericality: true, allow_nil: true

  validates :kpi_type, :inclusion => {:in => COMPLETE_TYPE_OPTIONS, :message => "%{value} is not valid"}

  # Campaigns-KPIs relationship
  has_and_belongs_to_many :campaigns

  # KPIs-Segments relationship
  has_many :kpis_segments, dependent: :destroy

  # KPIs-Goals relationship
  has_many :goals

  accepts_nested_attributes_for :kpis_segments, reject_if: lambda { |x| x[:text].blank? }, allow_destroy: true
  accepts_nested_attributes_for :goals

  scope :global_and_custom, lambda{|company| where('company_id is null or company_id=?', company) }
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
    only_goal_types = OUT_BOX_TYPE_OPTIONS + ['number']
    if only_goal_types.include?(self.kpi_type)
      self.kpis_segments.delete_all
    else
      self.goals.where(kpis_segment_id: nil).delete_all
    end
  end

end
