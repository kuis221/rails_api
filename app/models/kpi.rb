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

  extend FriendlyId
  friendly_id :name, use: :scoped, scope: :company_id

  scoped_to_company

  TYPE_OPTIONS = {"number" => ["integer", "decimal", "money"],
                  "count" => ["radio", "dropdown", "checkbox"],
                  "percentage" => ["integer", "decimal"]}

  attr_accessible :name, :description, :kpi_type, :capture_mechanism

  validates :name, presence: true, uniqueness: {scope: :company_id}
  validates :company_id, numericality: true, allow_nil: true

  validates :kpi_type, :inclusion => {:in => TYPE_OPTIONS.keys + ['promo_hours', 'photos', 'videos'],
    :message => "%{value} is not valid"}

  # Campaigns-KPIs relationship
  has_and_belongs_to_many :campaigns

  scope :global_and_custom, lambda{|company| where('company_id is null or company_id=?', company) }
  scope :in_module, lambda{ where('module is not null and module != \'\'') }
end
