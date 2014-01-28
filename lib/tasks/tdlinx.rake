require 'csv'

module CommonMethods

  $words_to_strip = ["bar", "pub", "tavern", "restaurant", "lounge", "club",
                    "saloon", "grill","nightclub", "cafe","hotel", "llc",
                    "inn", "the", "and", "n"]

  def fix_address(address)
    address.gsub(/(\s|,|\A)(rd\.?)(\s|,|\z)/i,'\1Road\3').
            gsub(/(\s|,|\A)(st\.?)(\s|,|\z)/i,'\1Street\3').
            gsub(/(\s|,|\A)(ste\.?)(\s|,|\z)/i,'\1Suite\3').
            gsub(/(\s|,|\A)(av|ave\.?)(\s|,|\z)/i,'\1Avenue\3').
            gsub(/(\s|,|\A)(blvd\.?)(\s|,|\z)/i,'\1Boulevard\3').
            gsub(/(\s|,|\A)(hwy\.?)(\s|,|\z)/i,'\1Highway\3').
            gsub(/(\s|,|\A)(fifth\.?)(\s|,|\z)/i,'\15th\3').
            gsub(/(\s|,|\A)(dr\.?)(\s|,|\z)/i,'\1Drive\3').
            gsub(/(\s|,|\A)(w\.?)(\s|,|\z)/i,'\1West\3').
            gsub(/(\s|,|\A)(s\.?)(\s|,|\z)/i,'\1South\3').
            gsub(/(\s|,|\A)(e\.?)(\s|,|\z)/i,'\1East\3').
            gsub(/(\s|,|\A)(n\.?)(\s|,|\z)/i,'\1North\3').
            gsub(/(\s|,|\A)(ne\.?)(\s|,|\z)/i,'\1Northeast\3').
            gsub(/(\s|,|\A)(nw\.?)(\s|,|\z)/i,'\1Northwest\3').
            gsub(/(\s|,|\A)(se\.?)(\s|,|\z)/i,'\1Southeast\3').
            gsub(/(\s|,|\A)(sw\.?)(\s|,|\z)/i,'\1Southwest\3').
            gsub(/(\s|,|\A)(Parkway)(\s|,|\z)/i,'\1Pkwy\3').
            strip
  end

  def fix_city(city)
    city.gsub(/(\s|,|\A)(st\.?)(\s|,|\z)/i,'\1Saint\3').strip if city
  end

  def build_address(fields)
    fields.reject{|v| v.nil? || v.strip == '' }.join(', ').gsub(/\s+/,' ')
  end

  def fix_name(name)
    name.gsub(/[^0-9A-Za-z ]/, '').
         downcase.
         squish.split.delete_if{|x| $words_to_strip.include?(x.downcase)}.join(' ')
  end
end

namespace :tdlinx do
  namespace :import do
    desc "Import TDLinx codes data"
    task :codes => :environment do
      include CommonMethods

      usa_states = Country.new('US').states
      CSV.foreach("#{Rails.root}/db/TDLinx.csv", :headers => true) do |row|
        if row['store_code'].present?
          row['retailer_address'] = fix_address(row['retailer_address'])
          row['retailer_city'] = fix_city(row['retailer_city']).capitalize
          row['fixed_address'] = build_address([ fix_address(row['retailer_address']), row['retailer_city'], usa_states[row['retailer_state']]['name'] ])
          begin
            if TdLinx.create!(row.to_hash)
              p "TDLinx code: #{row['store_code']} imported!"
            end
          rescue ActiveRecord::RecordNotUnique => e
            next
          end
        end
      end
    end
  end

  namespace :update do
    desc "Update TDLinx code for places"
    task :codes => :environment do
      include CommonMethods

      c=0
      CSV.open("tmp/Venues-Not-Found.csv", "wb") do |not_found|
        not_found << ["Id", "Name", "Address"]
        CSV.open("tmp/Venues-Different-Names.csv", "wb") do |different_names|
          different_names << ["Name", "Address", "TDLinx Code", "Source"]

          Place.where("td_linx_code IS NULL or td_linx_code=''").each do |place|
            place_address = build_address([fix_address(place.street), fix_city(place.city), place.state])
            #Compare place and tdlinx record addresses
            result = TdLinx.where('lower(fixed_address)=?', place_address.downcase)

            if result.present?
              #Clean place names
              fixed_place_name = fix_name(place.name)
              fixed_tdlinx_name = fix_name(result.first.retailer_dba_name)
              p "#{place.name} ==> #{fixed_place_name}"
              p "#{result.first.retailer_dba_name} ==> #{fixed_tdlinx_name}"

              if fixed_place_name.include?(fixed_tdlinx_name) || fixed_tdlinx_name.include?(fixed_place_name)
                if place.update_column('td_linx_code', result.first.store_code)
                  c = c+1
                end
              else
                different_names << [place.name, place_address, '', 'Brandscopic DB']
                different_names << [result.first.retailer_dba_name, result.first.fixed_address, result.first.store_code, "External"]
                different_names << []
              end
              p "---------------------------------------------"
            else
              not_found << [place.id, place.name, place_address]
            end
          end
          p "#{c} places were updated"
        end
      end
    end
  end
end