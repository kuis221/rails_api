require 'rails_helper'

describe FacetsHelper, :type => :helper do
  let(:company){ FactoryGirl.create(:company) }
  let(:company_user){ FactoryGirl.create(:company_user, company: company) }

  before { allow(helper).to receive(:current_company).and_return(company) }
  before { allow(helper).to receive(:current_company_user).and_return(company_user) }
  before { allow(helper).to receive(:controller_name).and_return('my_controller') }

  describe 'build_custom_filters_bucket' do
    it "should return empty if no custom filters have been created" do
      expect(helper.build_custom_filters_bucket).to eql []
    end

    it "should the saved custom filter" do
      filter = FactoryGirl.create(:custom_filter, name: 'CustomFilter1',
        owner: company_user, apply_to: 'my_controller',
        filters: 'my-filter=true', group: 'My Filters')
      expect(helper.build_custom_filters_bucket).to eql [
        {
          label: 'MY FILTERS', items: [
            {id: "my-filter=true&id="+filter.id.to_s, label: "CustomFilter1", name: :custom_filter, count: 1, selected: false}
          ]
        }
      ]
    end

    it "should the saved custom filters for the company" do
      filter = FactoryGirl.create(:custom_filter, name: 'CustomFilter1',
        owner: company, apply_to: 'my_controller',
        filters: 'my-filter=true', group: 'My Filters')
      expect(helper.build_custom_filters_bucket).to eql [
        {
          label: 'MY FILTERS', items: [
            {id: "my-filter=true&id="+filter.id.to_s, label: "CustomFilter1", name: :custom_filter, count: 1, selected: false}
          ]
        }
      ]
    end

    it "should the saved custom filters grouped by :group" do
      global_filter = FactoryGirl.create(:custom_filter, name: 'CustomCompanyFilter1',
        owner: company, apply_to: 'my_controller',
        filters: 'my-filter=true', group: 'Global Filters')
      user_filter = FactoryGirl.create(:custom_filter, name: 'CustomUserFilter1',
        owner: company_user, apply_to: 'my_controller',
        filters: 'my-filter=true', group: 'My Filters')
      expect(helper.build_custom_filters_bucket).to eql [
        {
          label: 'GLOBAL FILTERS', items: [
            {id: "my-filter=true&id="+global_filter.id.to_s, label: "CustomCompanyFilter1", name: :custom_filter, count: 1, selected: false}
          ]
        },
        {
          label: 'MY FILTERS', items: [
            {id: "my-filter=true&id="+user_filter.id.to_s, label: "CustomUserFilter1", name: :custom_filter, count: 1, selected: false}
          ]
        }
      ]
    end
  end
end