class TopAccountsMailer < ActionMailer::Base
  default from: 'support@brandscopic.com'

  def file_missing
    recipients = %w(
      cjaskot@brandscopic.com kkubik@brandscopic.com Elliott.Higdon@legacymp.com
      Joshua.Silverstein@legacymp.com Dan.Berliner@legacymp.com
      Alexis.Bannos@legacymp.com Christy.Sabol@legacymp.com Jordan.Lipshutz@legacymp.com
    )
    mail to: recipients, subject: 'Jameson Locals Accounts List Synch – File Not Found'
  end

  def invalid_format(files)
    recipients = %w(
      cjaskot@brandscopic.com kkubik@brandscopic.com Elliott.Higdon@legacymp.com
      Joshua.Silverstein@legacymp.com Dan.Berliner@legacymp.com  Alexis.Bannos@legacymp.com
      Christy.Sabol@legacymp.com
    )
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
    recipients = %w(
      cjaskot@brandscopic.com kkubik@brandscopic.com Elliott.Higdon@legacymp.com
      Joshua.Silverstein@legacymp.com Dan.Berliner@legacymp.com Alexis.Bannos@legacymp.com
      Christy.Sabol@legacymp.com  Jordan.Lipshutz@legacymp.com
    )
    mail to: recipients, subject: 'Jameson Locals Accounts List Synch – Successfully Completed'
  end
end
