class TopAccountsMailer < ActionMailer::Base
  default from: 'support@brandscopic.com'

  def file_missing
    recipients = ENV['TOP_ACCOUNTS_FILE_MISSING_EMAILS'].split(',')
    mail to: recipients, subject: 'Jameson Locals Accounts List Synch – File Not Found'
  end

  def invalid_format(files)
    recipients = ENV['TOP_ACCOUNTS_INVALID_FORMAT_EMAILS'].split(',')
    files.each do |path|
      attachments[File.basename(path)] = File.read(path)
    end
    mail to: recipients, subject: 'Top 100 Accounts List Synch – Improper Format'
  end

  def success(total, flagged, existed, created, flagged_before)
    @total = total
    @flagged = flagged
    @existed = existed
    @created = created
    @flagged_before = flagged_before
    recipients = ENV['TOP_ACCOUNTS_SUCCESS_EMAILS'].split(',')
    mail to: recipients, subject: 'Jameson Locals Accounts List Synch – Successfully Completed'
  end
end
