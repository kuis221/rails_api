namespace :db do
  namespace :populate do
    desc 'Add activities'
    task :activities => :environment do
      user_ids = User.all.map(&:id)
      100.times do
        start_date = Random.rand(90).days.send([:ago, :from_now].sample) - Random.rand(12).hours - Random.rand(60).minutes
        end_date = start_date + Random.rand(3).days
        Activity.create({name: Faker::Lorem.words.join(' '), start_date: start_date, end_date: end_date, created_by_id: user_ids.sample}, without_protection: true)
      end
    end
  end
end