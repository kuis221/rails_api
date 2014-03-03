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
  let(:field) { FactoryGirl.create(:form_field_brand, settings: {}, fieldable: activity_type) }
  let(:activity_type) { FactoryGirl.create(:activity_type, company: company) }
  let(:company) { FactoryGirl.create(:company) }

  before { Company.current = company }

  describe "#field_options" do
    it "should return all brands for company campaigns if it is a new record" do
      field = FormField::Brand.new(settings: {})
      brands = FactoryGirl.create_list(:brand, 2)
      campaign = FactoryGirl.create(:campaign, brand_ids: brands.map(&:id), company: company)
      activity_result = ActivityResult.new(form_field: field)

      options = field.field_options(activity_result)
      expect(options[:collection]).to match_array(brands)
    end

    it "should return only brands for selected campaign if it is an existing record" do
      brand1 = FactoryGirl.create(:brand)
      brand2 = FactoryGirl.create(:brand)
      campaign = FactoryGirl.create(:campaign, brand_ids: [brand1.id], company: company)
      campaign.activity_types << activity_type
      venue = FactoryGirl.create(:venue, place: FactoryGirl.create(:place), company: company)
      activity = FactoryGirl.create(:activity, activity_type: activity_type, activitable: venue, campaign: campaign, company_user_id: 1)
      activity_result = FactoryGirl.create(:activity_result, activity: activity, form_field_id: field.id)

      options = field.field_options(activity_result)
      expect(options[:collection]).to match_array([brand1])
    end
  end

  describe "#field_classes" do
    it "should return generic class" do
      expect(field.field_classes).to eql(['input-xlarge'])
    end
  end

  describe "#store_value" do
    it "should return the values as is" do
      expect(field.store_value(1)).to eql 1
      expect(field.store_value("two")).to eql "two"
      expect(field.store_value(1.2)).to eql 1.2
    end
    it "should return the arrays as string" do
      expect(field.store_value([1])).to eql '1'
      expect(field.store_value([1, 2])).to eql '1,2'
      expect(field.store_value([])).to eql ""
    end
  end

  describe "#format_html" do
    it "should return the correct values" do
      expect(field.format_html(FactoryGirl.build(:activity_result, value: nil, form_field_id: field.id))).to eql nil
      expect(field.format_html(FactoryGirl.build(:activity_result, value: FactoryGirl.create(:brand, name: 'BrandT1').id, form_field_id: field.id))).to eql 'BrandT1'
      expect(field.format_html(FactoryGirl.build(:activity_result, value: "", form_field_id: field.id))).to eql nil
      expect(field.format_html(FactoryGirl.build(:activity_result, value: 123, form_field_id: field.id))).to eql ''
      expect(field.format_html(FactoryGirl.build(:activity_result, value: [FactoryGirl.create(:brand, name: 'BrandT2').id, FactoryGirl.create(:brand, name: 'BrandT3').id], form_field_id: field.id))).to eql 'BrandT2, BrandT3'
    end
  end
end