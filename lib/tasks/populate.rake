namespace :db do
  namespace :populate do
    task :all => ['db:populate:companies', 'db:populate:roles', 'db:populate:users','db:populate:brands','db:populate:campaigns','db:populate:events']


    desc 'Add 10 companies'
    task :companies => :environment do
      Company.populate(10) do |company|
        company.name = Faker::Company.name
      end
    end

    desc 'Add roles to each company'
    task :roles => :environment do
      Company.all.each do |company|
        ['Admin', 'Field Director', 'Field Manager', 'Field Staff', 'Client', 'Brand Ambassadors'].each do |name|
          Role.find_or_create_by_company_id_and_name({company_id: company.id, name: name, active: true}, without_protection: true)
        end
      end
    end


    desc 'Add users'
    task :users => :environment do

      emails = User.select('email').map(&:email)
      Company.all.each do |company|
        role_ids = Role.scoped_by_company_id.map(&:id)
        User.populate(40) do |user|
          email = nil
          begin
             email =  Faker::Internet.email([user.first_name, user.last_name].join(' '))
          end while emails.include?(email)
          emails.push email

          user.first_name = Faker::Name.first_name
          user.last_name = Faker::Name.last_name
          user.email = Faker::Internet.email([user.first_name, user.last_name].join(' '))
          user.role_id = role_ids.sample
          user.company_id = company.id
          user.city = Faker::Address.city
          user.country = Country.all.sample[1]
          user.state = Country.find_country_by_alpha2(user.country).states.keys.sample
          user.company_id = company.id
          user.aasm_state = ['active', 'active', 'active', 'invited', 'inactive', 'active']
          user.encrypted_password = '$2a$10$/cMvcJN5c.AHCpkunKYvue5a5bGwxHYWftv3VT/ZJBKk874.MLvLS' # =>>> 'Test1234'
          user.confirmed_at (user.aasm_state == 'invited' ? nil : DateTime.now)
        end
      end
    end

    desc 'Load the brands.yml file into the database'
    task :brands => :environment do
      brands = YAML.load_file(File.join(Rails.root,'lib','assets','brands.yml'))
      Company.all.each do |company|
        brands.each do |portfolio_name, brands|
          portfolio = company.brand_portfolios.find_or_create_by_name(portfolio_name)
          actual_brands = portfolio.brands.map(&:name)
          (brands - actual_brands).each do |brand_name|
            portfolio.brands << Brand.find_or_create_by_name(brand_name)
          end
        end
      end
    end

    desc 'Create test campaigns'
    task :campaigns => :environment do
      def build_campaign_name
        @brands ||= Brand.all.map(&:name)
        @suffixes = ['January '+['12','13','14'].sample,'February '+['12','13','14'].sample,'March '+['12','13','14'].sample,'April '+['12','13','14'].sample,'May '+['12','13','14'].sample,'June '+['12','13','14'].sample,'July '+['12','13','14'].sample,'August '+['12','13','14'].sample,'September '+['12','13','14'].sample,'Octuber '+['12','13','14'].sample,'November '+['12','13','14'].sample,'December '+['12','13','14'].sample,'FY13','FY12', 'FY14','FY13','FY12', 'FY14','FY13','FY12', 'FY14']
        "#{@brands.sample} #{@suffixes.sample}"
      end
      Company.all.each do |company|
        Campaign.populate(30) do |campaign|
          campaign.name = build_campaign_name
          campaign.description = Faker::Lorem.paragraphs
          campaign.aasm_state = ['active', 'closed','active','active','inactive','active','active']
          campaign.company_id = company.id
        end
      end
    end

    desc 'Create test events on each campaign'
    task :events => :environment do
      Campaign.all.each do |campaign|
        Event.populate(rand(10..20)) do |event|
          event.start_at = rand(0..10).send([:weeks,:days,:months].sample).send([:ago, :from_now].sample) + rand(1..24).hours + rand(0..60).minutes
          event.end_at = event.start_at + rand(1..2).send([:days, :hours].sample)
          event.active = true
          event.campaign_id = campaign.id
          event.company_id = campaign.company_id
        end
      end
    end


  end
end