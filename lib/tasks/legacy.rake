require 'legacy'
require 'csv'

namespace :legacy do
  namespace :migrate do
    desc 'Sync the events from the LegacyV3 app'
    task :events => :environment do
      Legacy::Migration.synchronize_programs(ENV['PROGRAMS'].split(/\s*,\s*/).compact.map(&:to_i))
    end

  end

  namespace :import do
    desc 'Import a list of users into a database specified by IMPORT_DB'
    task :users, [:file] => :environment do |t, args|
      args.with_defaults(:file => "#{Rails.root}/db/users.csv")
      csv_text = File.read(args.file)
      csv = CSV.parse(csv_text, :headers => true)
      company = Company.find_by_name('Legacy Marketing Partners')
      inviter = company.company_users.order('id').first.user
      User.current = inviter
      all_markets = []
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
            invited_by: inviter,
            company_users_attributes: [{company_id: company.id, role_id: role.id}]
          }

          user = User.new(user_info, without_protection: true)
          user.skip_confirmation!
          company_user = user.company_users[0]

          if row['Brands list']
            brands_names=row['Brands list'].split(/,|,? and /).map(&:strip).compact.reject{|n| n == ''}
            brands_names.each do|name|
              member = BrandPortfolio.find_by_name(name.strip) or Brand.find_by_name(name.strip)
              company_user.memberships.build(memberable: member)
            end
          end

          if row['Markets list']
            markets_names=row['Markets list'].split(/,|,? and /).map(&:strip).compact
            all_markets += markets_names
            markets_names.each do |name|
              if area = Area.find_by_name(name.strip)
                company_user.memberships.build(memberable:  area)
              end
            end
          end

          if user.save(validate: false)
            p "User: #{user.full_name} [#{user.email}] imported!"
            user.invite!
          else
            p "Unable to save user: #{user.inspect}: #{user.errors.full_messages}"
          end
        else
          p "Email already exists: #{row['Email']}... ignoring!"
        end
      end
      missing_markets = all_markets.uniq.compact.reject{|n| n == '' || company.areas.find_by_name(n).present?}

      p "Missing markets:\n#{missing_markets.inspect}"
    end

    desc 'Reassign the campaings to the users'
    task :assign_campaigns, [:file] => :environment do |t, args|
      args.with_defaults(:file => "#{Rails.root}/db/users.csv")
      csv_text = File.read(args.file)
      csv = CSV.parse(csv_text, :headers => true)
      company = Company.find_by_name('Legacy Marketing Partners')
      inviter = company.company_users.order('id').first.user
      User.current = inviter
      all_markets = []
      csv.each do |row|
        user = User.where('lower(email)=?', row['Email'].downcase.strip).first
        if user.present?

          company_user = user.company_users[0]

          if row['Brands list']
            brands_names=row['Brands list'].split(/,|,? and /).map(&:strip).compact.reject{|n| n == ''}
            brands_names.each do|name|
              member = BrandPortfolio.find_by_name(name.strip) || Brand.find_by_name(name.strip)
              company_user.memberships.create(memberable: member) unless member.nil? || company_user.memberships.any?{|m| m.memberable == member}
            end
          end

          if user.save(validate: false)
            p "User: #{user.full_name} [#{user.email}] imported!"
          else
            p "Unable to save user: #{user.inspect}: #{user.errors.full_messages}"
          end
        else
          p "Email already exists: #{row['Email']}... ignoring!"
        end
      end
      missing_markets = all_markets.uniq.compact.reject{|n| n == '' || company.areas.find_by_name(n).present?}

      p "Missing markets:\n#{missing_markets.inspect}"
    end
  end
end
