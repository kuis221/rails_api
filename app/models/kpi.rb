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
#

class Kpi < ActiveRecord::Base
  track_who_does_it

  scoped_to_company

  TYPE_OPTIONS = {"number" => ["Whole Number", "Decimal", "Money"],
                  "count" => ["Radio Button", "Dropdown", "Checkbox"],
                  "percentage" => ["Whole Number", "Decimal"]}

  attr_accessible :name, :description, :kpi_type, :capture_mechanism, :kpis_segments_attributes

  validates :name, presence: true, uniqueness: {scope: :company_id}
  validates :company_id, presence: true

  validates :kpi_type, :inclusion => {:in => TYPE_OPTIONS,
    :message => "%{value} is not valid"}

  # Campaigns-KPIs relationship
  has_and_belongs_to_many :campaigns

  # KPIs-Segments relationship
  has_many :kpis_segments, dependent: :destroy

  accepts_nested_attributes_for :kpis_segments, reject_if: lambda { |x| x[:text].blank? }, allow_destroy: true
end
