require 'rails_helper'

describe Autocomplete, type: :model do
  describe 'search method', search: true do
    let(:company) { create(:company) }
    let(:company_user) { create(:company_user, company: company) }
    let(:scope) { 'events' }
    let(:params) { { id: scope, q: 'jam' } }
    let(:subject) { described_class.new(scope, company_user, params) }

    describe 'Campaign bucket' do
      let(:active) { create(:campaign, company: company, name: 'Jameson FY14') }
      let(:inactive) { create(:campaign, company: company, name: 'Jamaica FY14', aasm_state: 'inactive') }
      let(:bucket) { subject.search.find { |b| b[:label] == 'Campaigns' } }

      before do
        active && inactive
        Sunspot.commit
      end

      it 'returns only active campaigns if no settings have been defined' do
        expect(bucket).to eql(
          label: 'Campaigns', value: [{ label: '<i>Jam</i>eson FY14', value: active.id.to_s, type: 'campaign' }]
        )
      end

      it 'returns inactive campaigns if user have enabled it' do
        create(:filter_setting, company_user: company_user, apply_to: 'events',
               settings: %w(campaigns_events_present show_inactive_items))
        expect(bucket).to eql(
          label: 'Campaigns', value: [
            { label: '<i>Jam</i>eson FY14', value: active.id.to_s, type: 'campaign' },
            { label: '<i>Jam</i>aica FY14', value: inactive.id.to_s, type: 'campaign' }
          ]
        )
      end

      it 'does not include the inactive campaign if the user have disabled show inactive option' do
        create(:filter_setting, company_user: company_user, apply_to: 'events',
               settings: %w(campaigns_events_present))
        expect(bucket).to eql(
          label: 'Campaigns', value: [{ label: '<i>Jam</i>eson FY14', value: active.id.to_s, type: 'campaign' }]
        )
      end
    end
  end
end
