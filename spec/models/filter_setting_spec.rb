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

  describe '#filter_settings_for' do
    it 'should return the correct array of results depending on stored settings' do
      filter_setting = create(:filter_setting, company_user_id: 1, apply_to: 'events', settings: '["campaigns_events_active", "brands_events_active", "brands_events_inactive", "users_events_active"]')
      expect(filter_setting.filter_settings_for('Campaigns', 'events', true)).to match_array ['active']
      expect(filter_setting.filter_settings_for('Brands', 'events')).to match_array [true, false]
      expect(filter_setting.filter_settings_for('Users', 'events')).to match_array [true]
      expect(filter_setting.filter_settings_for('Brand Portfolios', 'events')).to match_array []
    end
  end
end
