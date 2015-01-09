class RsvpReportMailer < ActionMailer::Base
  default from: 'support@brandscopic.com'

  def file_missing
    recipients = ENV['RSVP_FILE_MISSING_EMAILS'].split(',')
    mail to: recipients, subject: 'RSVP Report Synch – File Not Found'
  end

  def invalid_format(files)
    recipients = ENV['RSVP_INVALID_FORMAT_EMAILS'].split(',')
    files.each do |path|
      attachments[File.basename(path)] = File.read(path)
    end
    mail to: recipients, subject: 'RSVP Report Synch – Improper Format'
  end

  def success(created, failed, files = [])
    @created = created
    @failed = failed
    recipients = ENV['RSVP_SUCCESS_EMAILS'].split(',')

    files.each do |path|
      attachments[File.basename(path)] = File.read(path)
    end

    mail to: recipients, subject: 'RSVP Report Synch – Successfully Completed'
  end
end
