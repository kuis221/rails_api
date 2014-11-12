desc "This task is called by the Heroku scheduler add-on to update the score of those venues that have the dirty flag on"
task :update_venue_score => :environment do
  puts "Updating venue scores..."
  Venue.where(score_dirty: true).each do |venue|
    venue.compute_scoring.save
    puts "Venue #{venue.name}[#{venue.id}] updated score: #{venue.score}"
  end
  puts "done."
end


desc "This task is called by the Heroku scheduler add-on to clear old sessions"
task :clear_expired_sessions => :environment do
  ActiveRecord::SessionStore::Session.delete_all(["updated_at < ?", Devise.remember_for.ago])
end