# == Schema Information
#
# Table name: marques
#
#  id         :integer          not null, primary key
#  brand_id   :integer
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe FormField::Marque, :type => :model do
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

      FactoryGirl.create(:form_field, fieldable: @activity_type, type: 'FormField::Brand', ordering: 1)
      ff_marque = FormField.find(FactoryGirl.create(:form_field, fieldable: @activity_type, type: 'FormField::Marque', ordering: 2).id)
      activity_result = FormFieldResult.new(form_field: ff_marque, resultable: activity)

      options = ff_marque.field_options(activity_result)
      expect(options[:collection]).to be_empty
    end

    it "should return empty collection for fields with not associated brands" do
      brand = FactoryGirl.create(:brand)
      campaign = FactoryGirl.create(:campaign, brand_ids: [brand.id], company: Company.current)
      campaign.activity_types << @activity_type
      venue = FactoryGirl.create(:venue, place: FactoryGirl.create(:place), company: Company.current)
      activity = FactoryGirl.create(:activity, activity_type: @activity_type, activitable: venue, campaign: campaign, company_user_id: 1)
      ff_brand = FactoryGirl.create(:form_field, fieldable: @activity_type, type: 'FormField::Brand', settings: {}, ordering: 1)
      FactoryGirl.create(:form_field_result, resultable: activity, form_field: ff_brand, value: brand.id)
      ff_marque = FactoryGirl.create(:form_field, fieldable: @activity_type, type: 'FormField::Marque', settings: {}, ordering: 2)
      activity_result = FactoryGirl.create(:form_field_result, resultable: activity, form_field: ff_marque)

      ff_marque = FormField.find(ff_marque.id)

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
      ff_brand = FactoryGirl.create(:form_field, type: 'FormField::Brand', fieldable: @activity_type, settings: {}, ordering: 1)
      activity_result = FactoryGirl.create(:form_field_result, resultable: activity, form_field: ff_brand, value: brand.id)
      @activity_type.form_fields.reload
      ff_marque = FactoryGirl.create(:form_field, type: 'FormField::Marque', fieldable: @activity_type, settings: {}, ordering: 2)
      activity_result = FactoryGirl.create(:form_field_result, resultable: activity, form_field: ff_marque, value: "#{marque1.id},#{marque2.id}")

      ff_marque = FormField.find(ff_marque.id)

      options = ff_marque.field_options(activity_result)
      expect(options[:collection]).to match_array([marque1, marque2])
    end

    it "should return marques associated to the only campaign brand" do
      brand = FactoryGirl.create(:brand)
      marque1 = FactoryGirl.create(:marque, brand: brand)
      marque2 = FactoryGirl.create(:marque, brand: brand)
      campaign = FactoryGirl.create(:campaign, brand_ids: [brand.id], company: Company.current)
      campaign.activity_types << @activity_type
      venue = FactoryGirl.create(:venue, place: FactoryGirl.create(:place), company: Company.current)
      activity = FactoryGirl.create(:activity, activity_type: @activity_type, activitable: venue, campaign: campaign, company_user_id: 1)
      ff_brand = FactoryGirl.create(:form_field, type: 'FormField::Brand', fieldable: @activity_type, settings: {}, ordering: 1)
      @activity_type.form_fields.reload
      ff_marque = FactoryGirl.create(:form_field, type: 'FormField::Marque', fieldable: @activity_type, settings: {}, ordering: 2)
      activity_result = FactoryGirl.build(:form_field_result, resultable: activity, form_field: ff_marque)

      ff_marque = FormField.find(ff_marque.id)

      options = ff_marque.field_options(activity_result)
      expect(options[:collection]).to match_array([marque1, marque2])
    end
  end
end
