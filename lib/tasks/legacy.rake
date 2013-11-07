require 'legacy'
require 'csv'

namespace :legacy do
  namespace :migrate do
    desc 'Sync the events from the LegacyV3 app'
    task :events => :environment do
      Legacy::Migration.synchronize_programs(ENV['PROGRAMS'].split(',').compact.map(&:to_i))
    end

  end

  namespace :import do
    desc 'Import a list of users into a database specified by IMPORT_DB'
    task :users, [:file] => :environment do |t, args|
      args.with_defaults(:file => "tmp/users.csv")
      csv_text = File.read(args.file)
      csv = CSV.parse(csv_text, :headers => true)
      company = Company.find_by_name('Legacy Marketing Partners')
      ActiveRecord::Base.transaction do
        csv.each do |row|
          user = User.where('lower(email)=?', row['Email'].downcase.strip).first
          if user.nil?
            role = company.roles.find_by_name(row['Group name']) or raise "Role '#{row['Group name']}' not found"
            user_info = {
              email: row['Email'],
              first_name: row['First name'],
              last_name: row['Last name'],
              phone_number: row['Work phone number'] || row['Mobile phone number'],
              city: row['City'],
              state: row['State'],
              street_address: row['Address 1'],
              unit_number: row['Address 2'],
              country: 'US',
              zip_code: row['Zip'],
              company_users_attributes: [{company_id: company.id, role_id: role.id}]
            }

            user = User.new(user_info, without_protection: true)
            company_user = user.company_users[0]

            if row['Brands list']
              brands_names=row['Brands list'].split(/,|,? and /).compact
              p "Brands: #{brands_names.inspect}"
              brands_names.each{|name| company_user.memberships.build(memberable: Brand.find_or_create_by_name(name)) }
            end

            if row['Markets list']
              markets_names=row['Markets list'].split(/,|,? and /)
              p "Markets: #{markets_names.inspect}"
              markets_names.each{|name| company_user.memberships.build(memberable:  Area.find_by_name(name)) }
            end

            p company_user.memberships.inspect


            if user.save(validate: false)
              p "SAVED!!"
            else
              p "Unable to save user: #{user.inspect}: #{user.errors.full_messages}"
            end
            break
          end
        end
        #raise ActiveRecord::Rollback
      end
    end
  end
end
