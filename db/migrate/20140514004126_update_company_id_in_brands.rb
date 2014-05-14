class UpdateCompanyIdInBrands < ActiveRecord::Migration
  def up
    Campaign.find_each do |campaign|
      campaign.brands.each do |brand|
        if brand.company_id.nil?
          brand.company_id = campaign.company_id
          brand.save
        elsif brand.company_id != campaign.company_id
          new_brand = Brand.find_or_create_by_name_and_company_id(brand.name, campaign.company_id)
          puts "\n\n\n Creating brand #{brand.name} in company #{campaign.company_id} for campaign: #{campaign.name} "
          raise 'Could not create brand: ' +new_brand.errors.full_messages.join(", ")  unless new_brand.persisted?
          campaign.brands.delete brand
          campaign.brands << new_brand
        end
      end
    end
  end

  def down
  end
end
