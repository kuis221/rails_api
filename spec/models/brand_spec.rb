# == Schema Information
#
# Table name: brands
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :integer
#  active        :boolean          default(TRUE)
#

require 'spec_helper'

describe Brand do

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name).case_insensitive }

  it { should have_and_belong_to_many(:campaigns) }
  it { should have_many(:brand_portfolios_brands) }
  it { should have_many(:brand_portfolios) }
  it { should have_many(:marques) }

  describe "marques_list" do
    it "should return the marques on a list separated by comma" do
      brand = FactoryGirl.create(:brand)
      brand.marques << FactoryGirl.create(:marque,  name: 'Marque 1')
      brand.marques << FactoryGirl.create(:marque,  name: 'Marque 2')
      brand.marques << FactoryGirl.create(:marque,  name: 'Marque 3')
      brand.marques_list.should == 'Marque 1,Marque 2,Marque 3'
    end
  end

  describe "marques_list=" do
    it "should create any non-existing marque into the app" do
      brand = FactoryGirl.build(:brand, marques_list: 'Marque 1,Marque 2,Marque 3')
      expect{
        brand.save!
      }.to change(Marque, :count).by(3)
      brand.reload.marques.map(&:name).should == ['Marque 1','Marque 2','Marque 3']
    end

    it "should create only the marque that does not exists into the app for the brand and allow repeated marque names for different brands" do
      #Another brand with a 'Marque 3'
      FactoryGirl.create(:brand, marques_list: 'Marque 3')
      #Our brand with a 'Marque 1' initially
      brand = FactoryGirl.create(:brand, marques_list: 'Marque 1')
      #Modify the marques list for our brand
      expect{
        brand.marques_list = 'Marque 1,Marque 2,Marque 3'
        brand.save!
      }.to change(Marque, :count).by(2)
      brand.reload.marques.map(&:name).should == ['Marque 1','Marque 2','Marque 3']
      Marque.all.map(&:name).should =~ ['Marque 1','Marque 2','Marque 3','Marque 3']
    end

    it "should remove any other marque from the brand not in the new list" do
      #Another brand with a 'Marque 3'
      FactoryGirl.create(:brand, marques_list: 'Marque 3')
      #Our brand with 3 marques initially
      brand = FactoryGirl.create(:brand, marques_list: 'Marque 1,Marque 2,Marque 3')
      brand.reload.marques.count.should == 3
      #Remove a marque from our brand
      expect{
        brand.marques_list = 'Marque 2,Marque 1'
        brand.save!
      }.to change(Marque, :count).by(-1)
      brand.reload.marques.map(&:name).should == ['Marque 1','Marque 2']
      Marque.all.map(&:name).should =~ ['Marque 1','Marque 2','Marque 3']
    end
  end
end
