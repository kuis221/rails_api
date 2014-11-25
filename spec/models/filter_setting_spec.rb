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

require 'rails_helper'

describe FilterSetting, type: :model do
  it { is_expected.to belong_to(:company_user) }
  it { is_expected.to validate_presence_of(:company_user_id) }
  it { is_expected.to validate_presence_of(:apply_to) }
  it { is_expected.to validate_numericality_of(:company_user_id) }
end
