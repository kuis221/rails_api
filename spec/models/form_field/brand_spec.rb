# == Schema Information
#
# Table name: form_fields
#
#  id             :integer          not null, primary key
#  fieldable_id   :integer
#  fieldable_type :string(255)
#  name           :string(255)
#  type           :string(255)
#  settings       :text
#  ordering       :integer
#  required       :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'spec_helper'

describe FormField::Brand do
  describe "#field_options" do
    before(:each) do
      Company.current = FactoryGirl.create(:company)
      @activity_type = FactoryGirl.create(:activity_type, company: Company.current)
    end

    it "should return all brands for company campaigns if it is a new record" do
      brands = FactoryGirl.create_list(:brand, 2)
      FactoryGirl.create(:campaign, brand_ids: brands.map(&:id), company: Company.current)
      ff_brand = FormField::Brand.new(settings: {})
      activity_result = ActivityResult.new(form_field: ff_brand)

      options = ff_brand.field_options(activity_result)
      expect(options[:collection]).to match_array(brands)
    end

    it "should return only brands for selected campaign if it is an existing record" do
      brand1 = FactoryGirl.create(:brand)
      brand2 = FactoryGirl.create(:brand)
      campaign = FactoryGirl.create(:campaign, brand_ids: [brand1.id], company: Company.current)
      campaign.activity_types << @activity_type
      venue = FactoryGirl.create(:venue, place: FactoryGirl.create(:place), company: Company.current)
      activity = FactoryGirl.create(:activity, activity_type: @activity_type, activitable: venue, campaign: campaign, company_user_id: 1)
      ff_brand = FactoryGirl.create(:form_field_brand, fieldable: @activity_type, settings: {})
      activity_result = FactoryGirl.create(:activity_result, activity: activity, form_field: ff_brand)

      options = ff_brand.field_options(activity_result)
      expect(options[:collection]).to match_array([brand1])
    end
  end
end