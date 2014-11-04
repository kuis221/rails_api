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
    let(:filter_setting) do
        create(:filter_setting, company_user_id: 1, apply_to: 'events',
               settings: '["campaigns_events_present", "campaigns_events_active", '\
                          '"brands_events_present", "brands_events_active", "brands_events_inactive", '\
                          '"company_users_events_present"]')
    end

    it 'returns the selected items' do
      expect(filter_setting.filter_settings_for(Campaign)).to match_array [true]
      expect(filter_setting.filter_settings_for(Brand)).to match_array [true, false]

      # With format as string
      expect(filter_setting.filter_settings_for(Campaign, format: :string)).to match_array ['active']
      expect(filter_setting.filter_settings_for(Brand, format: :string)).to match_array ['active', 'inactive']
    end

    it 'returns nil for models that does not have settings yet' do
      expect(filter_setting.filter_settings_for(BrandPortfolio)).to be_nil
    end

    it 'returns empty when user have not selected any option' do
      expect(filter_setting.filter_settings_for(CompanyUser)).to be_empty
    end
  end
end
