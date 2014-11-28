# == Schema Information
#
# Table name: filter_settings
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  apply_to        :string(255)
#  settings        :text
#  created_at      :datetime
#  updated_at      :datetime
#

class FilterSetting < ActiveRecord::Base
  belongs_to :company_user

  serialize :settings

  after_initialize :set_default_settings

  # Required fields
  validates :company_user_id, presence: true, numericality: true
  validates :apply_to, presence: true

  def set_default_settings
    self.settings ||= []
  end
end
