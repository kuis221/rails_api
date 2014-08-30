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

  # Required fields
  validates :company_user_id, presence: true, numericality: true
  validates :apply_to, presence: true

  def filter_settings_for(bucket, controller_name, aasm=false)
    setting = "#{bucket.gsub(/\s+/, '_').downcase}_#{controller_name}"
    status = []

    if aasm == true
      status.push('active') if settings.include?(setting+'_active')
      status.push('inactive') if settings.include?(setting+'_inactive')
    else
      status.push(true) if settings.include?(setting+'_active')
      status.push(false) if settings.include?(setting+'_inactive')
    end

    status
  end
end
