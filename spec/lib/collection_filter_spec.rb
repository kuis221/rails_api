require 'rails_helper'
require 'collection_filter'

describe CollectionFilter do
  describe 'filters method' do
    let(:company) { create(:company) }
    let(:role) { create(:role, company: company) }
    let(:company_user) { create(:company_user, company: company, role: role) }
    let(:params) { { id: scope } }
    let(:subject) { CollectionFilter.new(scope, company_user, params) }

    describe 'for events' do
      let(:scope) { 'events' }

      it 'should return the correct buckets' do
        expect(subject.filters.map { |b| b[:label] }).to eq([
          'Campaigns', 'Brands', 'Areas', 'People', 'Event Status', 'Active State', 'Saved Filters'])
      end

      describe 'as not admin user' do
        let(:role) { create(:non_admin_role) }

        include_examples 'for areas bucket'
        include_examples 'for active state bucket'
      end
    end

    describe 'for areas' do
      let(:scope) { 'areas' }

      include_examples 'for active state bucket'

      it 'should return the correct buckets' do
        expect(subject.filters.map { |b| b[:label] }).to eq([
          'Active State', 'Saved Filters'])
      end
    end

    describe 'for activity types' do
      let(:scope) { 'activity_types' }

      include_examples 'for active state bucket'

      it 'should return the correct buckets' do
        expect(subject.filters.map { |b| b[:label] }).to eq([
          'Active State', 'Saved Filters'])
      end
    end

    describe 'for venues' do
      let(:scope) { 'venues' }
      let(:search_stats) { nil }

      before do
        allow_any_instance_of(Sunspot::Rails::StubSessionProxy::Search)
          .to receive(:stats).and_return(search_stats)
      end

      include_examples 'for active state bucket'

      it 'should return the correct buckets' do
        expect(subject.filters.map { |b| b[:label] }).to eq([
          'Active State', 'Saved Filters'])
      end
    end

    describe 'company custom filters' do
      let(:scope) { :dummy }
      it 'returns empty if no custom filters have been created' do
        expect(subject.filters).to eql []
      end

      it 'returns the saved custom filter' do
        filter = create(:custom_filter, name: 'CustomFilter1',
          owner: company_user, apply_to: :dummy,
          filters: 'my-filter=true', group: 'My Filters')
        expect(subject.filters).to eql [
          {
            label: 'MY FILTERS', items: [
              { id: 'my-filter=true&id=' + filter.id.to_s, label: 'CustomFilter1', name: :custom_filter, count: 1, selected: false }
            ]
          }
        ]
      end

      it 'returns the saved custom filters for the company' do
        filter = create(:custom_filter, name: 'CustomFilter1',
          owner: company, apply_to: :dummy,
          filters: 'my-filter=true', group: 'My Filters')
        expect(subject.filters).to eql [
          {
            label: 'MY FILTERS', items: [
              { id: 'my-filter=true&id=' + filter.id.to_s, label: 'CustomFilter1', name: :custom_filter, count: 1, selected: false }
            ]
          }
        ]
      end

      it 'returns the saved custom filters grouped by :group' do
        global_filter = create(:custom_filter, name: 'CustomCompanyFilter1',
          owner: company, apply_to: :dummy,
          filters: 'my-filter=true', group: 'Global Filters')
        user_filter = create(:custom_filter, name: 'CustomUserFilter1',
          owner: company_user, apply_to: :dummy,
          filters: 'my-filter=true', group: 'My Filters')
        expect(subject.filters).to eql [
          {
            label: 'GLOBAL FILTERS', items: [
              { id: 'my-filter=true&id=' + global_filter.id.to_s, label: 'CustomCompanyFilter1', name: :custom_filter, count: 1, selected: false }
            ]
          },
          {
            label: 'MY FILTERS', items: [
              { id: 'my-filter=true&id=' + user_filter.id.to_s, label: 'CustomUserFilter1', name: :custom_filter, count: 1, selected: false }
            ]
          }
        ]
      end
    end
  end
end
