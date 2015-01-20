class JbbJamesonLocalsAccountMailer < ActionMailer::Base
  default from: 'support@brandscopic.com'

  def file_missing
    recipients = ENV['JAMESON_LOCALS_FILE_MISSING_EMAILS'].split(',')
    mail to: recipients, subject: 'Jameson Locals Accounts List Synch – File Not Found'
  end

  def invalid_format(files)
    recipients = ENV['JAMESON_LOCALS_INVALID_FORMAT_EMAILS'].split(',')
    files.each do |path|
      attachments[File.basename(path)] = File.read(path)
    end
    mail to: recipients, subject: 'Jameson Locals Accounts List Synch – Improper Format'
  end

  def success(total, existed, created, flagged_before, files)
    @total = total
    @existed = existed
    @created = created
    @flagged_before = flagged_before
    recipients = ENV['JAMESON_LOCALS_SUCCESS_EMAILS'].split(',')

    files.each do |name, path|
      attachments[name] = File.read(path)
    end
    mail to: recipients, subject: 'Jameson Locals Accounts List Synch – Successfully Completed'
  end
end
