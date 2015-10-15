namespace :jbb do
  desc 'Run the RSVP report process'
  task rsvp: :environment do
    puts 'rake jbb:rsvp started'
    processor = JbbFile::RsvpReport.new
    puts "FTP Directory: #{processor.ftp_folder}"
    processor.process if Time.current.utc.thursday? || ENV['FORCE'] == 'true'
  end
end
