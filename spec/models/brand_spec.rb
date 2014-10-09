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

require 'rails_helper'

describe Brand, type: :model do

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).case_insensitive }

  it { is_expected.to have_and_belong_to_many(:campaigns) }
  it { is_expected.to have_many(:brand_portfolios_brands) }
  it { is_expected.to have_many(:brand_portfolios) }
  it { is_expected.to have_many(:marques) }

  describe 'marques_list' do
    it 'should return the marques on a list separated by comma' do
      brand = create(:brand)
      brand.marques << create(:marque,  name: 'Marque 1')
      brand.marques << create(:marque,  name: 'Marque 2')
      brand.marques << create(:marque,  name: 'Marque 3')
      expect(brand.marques_list).to eq('Marque 1,Marque 2,Marque 3')
    end
  end

  describe 'marques_list=' do
    it 'should create any non-existing marque into the app' do
      brand = build(:brand, marques_list: 'Marque 1,Marque 2,Marque 3')
      expect do
        brand.save!
      end.to change(Marque, :count).by(3)
      expect(brand.reload.marques.map(&:name)).to eq(['Marque 1', 'Marque 2', 'Marque 3'])
    end

    it 'should create only the marque that does not exists into the app for the brand and allow repeated marque names for different brands' do
      # Another brand with a 'Marque 3'
      create(:brand, marques_list: 'Marque 3')
      # Our brand with a 'Marque 1' initially
      brand = create(:brand, marques_list: 'Marque 1')
      # Modify the marques list for our brand
      expect do
        brand.marques_list = 'Marque 1,Marque 2,Marque 3'
        brand.save!
      end.to change(Marque, :count).by(2)
      expect(brand.reload.marques.map(&:name)).to eq(['Marque 1', 'Marque 2', 'Marque 3'])
      expect(Marque.all.map(&:name)).to match_array(['Marque 1', 'Marque 2', 'Marque 3', 'Marque 3'])
    end

    it 'should remove any other marque from the brand not in the new list' do
      # Another brand with a 'Marque 3'
      create(:brand, marques_list: 'Marque 3')
      # Our brand with 3 marques initially
      brand = create(:brand, marques_list: 'Marque 1,Marque 2,Marque 3')
      expect(brand.reload.marques.count).to eq(3)
      # Remove a marque from our brand
      expect do
        brand.marques_list = 'Marque 2,Marque 1'
        brand.save!
      end.to change(Marque, :count).by(-1)
      expect(brand.reload.marques.map(&:name)).to eq(['Marque 1', 'Marque 2'])
      expect(Marque.all.map(&:name)).to match_array(['Marque 1', 'Marque 2', 'Marque 3'])
    end
  end
end
