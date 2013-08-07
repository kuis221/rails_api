namespace :db do
  namespace :populate do
    task :all => ['db:populate:companies', 'db:populate:places', 'db:populate:roles', 'db:populate:teams', 'db:populate:users','db:populate:brands','db:populate:campaigns','db:populate:events']


    desc 'Add sample places to DB'
    task :places => :environment do
      YAML.load_file(File.join(Rails.root,'lib','assets','places.yml')).each do |record|
          params = record[1].reject{|k, v| k == 'id'}.merge({do_not_connect_to_api: true})
          params['types'] = YAML.load(params['types']) rescue []
          Place.create(params, without_protection: true)
      end
    end

    desc 'Add 2 companies'
    task :companies => :environment do
      Company.populate(2) do |company|
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
        role_ids = Role.scoped_by_company_id(company.id).map(&:id)
        User.populate(40) do |user|
          email = nil
          begin
             email =  Faker::Internet.email([user.first_name, user.last_name].join(' '))
          end while emails.include?(email)
          emails.push email

          user.first_name = Faker::Name.first_name
          user.last_name = Faker::Name.last_name
          user.email = Faker::Internet.email([user.first_name, user.last_name].join(' '))
          user.city = Faker::Address.city
          user.country = 'US'
          user.state = Country.find_country_by_alpha2(user.country).states.keys.sample
          user.encrypted_password = '$2a$10$/cMvcJN5c.AHCpkunKYvue5a5bGwxHYWftv3VT/ZJBKk874.MLvLS' # =>>> 'Test1234'
          user.confirmed_at  = [DateTime.now, DateTime.now, DateTime.now, DateTime.now, nil, DateTime.now]
          user.invitation_accepted_at = user.confirmed_at
          user.invitation_token = user.invitation_accepted_at.present? ? nil : Faker::Lorem.characters(30)

          CompanyUser.populate(1) do |cu|
            cu.role_id = role_ids.sample
            cu.company_id = company.id
            cu.user_id = user.id
            cu.active = [true, true, true, false, true, false, true, true]
          end
        end

        all_users = company.company_users.all.shuffle
        company.teams.each do |team|
          team.users = all_users.sample(Random.rand(11))
        end
      end
    end

    desc 'Add teams'
    task :teams => :environment do
      team_names = YAML.load_file(File.join(Rails.root,'lib','assets','teams.yml'))
      Company.all.each do |company|
        names = team_names.shuffle
        Team.populate(6) do |team|
          team.name = names.pop(5)
          team.description = Faker::Lorem.paragraph
          team.company_id =  company.id
          team.active = [true, true, true, false, true, false, true, true]
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
        user_ids = company.company_users.map(&:id)
        team_ids = company.teams.map(&:id)
        Campaign.populate(30) do |campaign|
          campaign.name = build_campaign_name
          campaign.description = Faker::Lorem.paragraphs
          campaign.aasm_state = ['active', 'closed','active','active','inactive','active','active']
          campaign.company_id = company.id

          tmp_list = user_ids.shuffle
          Membership.populate(Random.rand(5)) do |membership|
            membership.company_user_id = tmp_list.pop
            membership.memberable_id = campaign.id
            membership.memberable_type = 'Campaign'
          end

          tmp_list = team_ids.shuffle
          Teaming.populate(Random.rand(team_ids.size)) do |teaming|
            teaming.team_id = tmp_list.pop
            teaming.teamable_id = campaign.id
            teaming.teamable_type = 'Campaign'
          end
        end
      end
    end

    desc 'Create test events on each campaign'
    task :events => :environment do
      places = Place.all.map(&:id)
      Company.all.each do |company|
        user_ids = company.company_users.active.map(&:id)
        team_ids = company.teams.active.map(&:id)
        Campaign.scoped_by_company_id(company.id).all.each do |campaign|
          Event.populate(rand(10..20)) do |event|
            event.start_at = rand(0..10).send([:weeks,:days,:months].sample).send([:ago, :from_now].sample) + rand(1..24).hours + rand(0..60).minutes
            event.end_at = event.start_at + rand(1..2).send([:days, :hours].sample)
            event.active = true
            event.campaign_id = campaign.id
            event.company_id = company.id
            event.place_id = places
          end
          campaign.events.each do |event|
            if event.user_ids.size == 0
              users = user_ids.sample(Random.rand(5))
              event.user_ids = users
              event.team_ids = team_ids.sample(Random.rand(2))
              users += company.company_users.joins(:teams).where(teams: {id: event.team_ids} ).map(&:id)

              Task.populate(Random.rand(5)) do |task|
                task.event_id = event.id
                task.company_user_id = (users+[nil, nil]).sample
                task.completed = [true, false]
                task.due_at = Date.today + (Random.rand(7)*[1, -1].sample).days
                task.title = Faker::Lorem.sentence(4 + Random.rand(6))
                task.active = [true, true, false, true, true]
                task.id = event.id
              end
            end
          end
        end
      end
    end


  end
end