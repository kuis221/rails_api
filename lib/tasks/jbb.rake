namespace :jbb do
  desc 'Run the RSVP report process'
  task rsvp: :environment do
    JbbFile::RsvpReport.new.process if Time.current.utc.thursday?
  end
end