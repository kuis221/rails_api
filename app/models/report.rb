# == Schema Information
#
# Table name: reports
#
#  id            :integer          not null, primary key
#  company_id    :integer
#  name          :string(255)
#  description   :text
#  active        :boolean          default(TRUE)
#  created_by_id :integer
#  updated_by_id :integer
#  rows          :text
#  columns       :text
#  values        :text
#  filters       :text
#

class Report < ActiveRecord::Base
  # Created_by_id and updated_by_id fields
  track_who_does_it

  scoped_to_company

  validates :name, presence: true, uniqueness: {scope: :company_id}
  validates :company_id, presence: true, numericality: true

  scope :active, -> { where(active: true) }

  before_validation :format_fields

  serialize :rows
  serialize :columns
  serialize :values
  serialize :filters

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  protected
    def format_fields
      ['rows', 'columns', 'values', 'filters'].each do |attribute|
        value = self.attributes[attribute]
        write_attribute attribute, value.map{|k, v| v.to_h } if value.is_a?(ActionController::Parameters)
      end
    end
end
