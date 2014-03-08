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

describe FormField::Marque do
  describe "#field_options" do
    before(:each) do
      Company.current = FactoryGirl.create(:company)
      @activity_type = FactoryGirl.create(:activity_type, company: Company.current)
    end

    it "should return empty marques if it is a new record" do
      campaign = FactoryGirl.create(:campaign, company: Company.current)
      campaign.activity_types << @activity_type
      event = FactoryGirl.create(:event, campaign: campaign)
      activity = FactoryGirl.create(:activity, activity_type: @activity_type, activitable: event, campaign: campaign, company_user_id: 1)

      ff_marque = FormField::Marque.new
      activity_result = ActivityResult.new(form_field: ff_marque, activity: activity)

      options = ff_marque.field_options(activity_result)
      expect(options[:collection]).to be_empty
    end

    it "should return empty marques for brands with not associated marques" do
      brand = FactoryGirl.create(:brand)
      campaign = FactoryGirl.create(:campaign, brand_ids: [brand.id], company: Company.current)
      campaign.activity_types << @activity_type
      venue = FactoryGirl.create(:venue, place: FactoryGirl.create(:place), company: Company.current)
      activity = FactoryGirl.create(:activity, activity_type: @activity_type, activitable: venue, campaign: campaign, company_user_id: 1)
      ff_brand = FactoryGirl.create(:form_field_brand, fieldable: @activity_type, settings: {}, ordering: 1)
      FactoryGirl.create(:activity_result, activity: activity, form_field: ff_brand, value: brand.id)
      ff_marque = FactoryGirl.create(:form_field_marque, fieldable: @activity_type, settings: {}, ordering: 2)
      activity_result = FactoryGirl.create(:activity_result, activity: activity, form_field: ff_marque)

      options = ff_marque.field_options(activity_result)
      expect(options[:collection]).to be_empty
    end

    it "should return marques associated to selected brand" do
      brand = FactoryGirl.create(:brand)
      marque1 = FactoryGirl.create(:marque, brand: brand)
      marque2 = FactoryGirl.create(:marque, brand: brand)
      campaign = FactoryGirl.create(:campaign, brand_ids: [brand.id], company: Company.current)
      campaign.activity_types << @activity_type
      venue = FactoryGirl.create(:venue, place: FactoryGirl.create(:place), company: Company.current)
      activity = FactoryGirl.create(:activity, activity_type: @activity_type, activitable: venue, campaign: campaign, company_user_id: 1)
      ff_brand = FactoryGirl.create(:form_field_brand, fieldable: @activity_type, settings: {}, ordering: 1)
      FactoryGirl.create(:activity_result, activity: activity, form_field: ff_brand, value: brand.id)
      ff_marque = FactoryGirl.create(:form_field_marque, fieldable: @activity_type, settings: {}, ordering: 2)
      activity_result = FactoryGirl.create(:activity_result, activity: activity, form_field: ff_marque, value: "#{marque1.id},#{marque2.id}")

      options = ff_marque.field_options(activity_result)
      expect(options[:collection]).to match_array([marque1, marque2])
    end
  end
end