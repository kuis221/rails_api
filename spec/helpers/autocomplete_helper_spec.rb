require 'rails_helper'

describe AutocompleteHelper, type: :helper do
  describe 'autocomplete_buckets', search: true do
    let(:company) { create(:company) }
    let(:company_user) { create(:company_user, company: company) }

    before do
      allow(helper).to receive(:current_company) { company }
      allow(helper).to receive(:current_company_user) { company_user }
      allow(helper).to receive(:params) { { apply_to: 'events', q: 'jam' } }
    end

    describe 'Campaign bucket' do
      let(:active) { create(:campaign, company: company, name: 'Jameson FY14') }
      let(:inactive) { create(:campaign, company: company, name: 'Jamaica FY14', aasm_state: 'inactive') }

      before { active && inactive }
      before { Sunspot.commit }

      it 'returns only active campaigns if no settings have been defined' do
        expect(helper.autocomplete_buckets(campaigns: [Campaign])).to eql([
          label: 'Campaigns', value: [ { label: '<i>Jam</i>eson FY14', value: active.id.to_s, type: 'campaign' } ]
        ])
      end

      it 'returns inactive campaigns if user have enabled it' do
        create(:filter_setting, company_user: company_user, apply_to: 'events',
               settings: %w(campaigns_events_present campaigns_events_active campaigns_events_inactive))
        expect(helper.autocomplete_buckets(campaigns: [Campaign])).to eql([
          label: 'Campaigns', value: [
            { label: '<i>Jam</i>eson FY14', value: active.id.to_s, type: 'campaign' },
            { label: '<i>Jam</i>aica FY14', value: inactive.id.to_s, type: 'campaign' }
          ]
        ])
      end

      it 'does not include the campaigns bucket if the user have disabled both options' do
        create(:filter_setting, company_user: company_user, apply_to: 'events',
               settings: %w(campaigns_events_present))
        expect(helper.autocomplete_buckets(campaigns: [Campaign])).to be_empty
        expect(helper.autocomplete_buckets(campaigns: [Campaign], people: [CompanyUser])).to eql([
          { label: 'People', value: [] }
        ])
      end
    end
  end
end
