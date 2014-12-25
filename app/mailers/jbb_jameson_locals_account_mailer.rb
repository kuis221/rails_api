class JbbJamesonLocalsAccountMailer < ActionMailer::Base
  default from: 'support@brandscopic.com'

  def file_missing
    recipients = %w(
      cjaskot@brandscopic.com kkubik@brandscopic.com Elliott.Higdon@legacymp.com
      Joshua.Silverstein@legacymp.com Dan.Berliner@legacymp.com
      Alexis.Bannos@legacymp.com Christy.Sabol@legacymp.com Jordan.Lipshutz@legacymp.com
    )
    mail to: recipients, subject: 'Jameson Locals Accounts List Synch – File Not Found'
  end

  def invalid_format(file_name)
    recipients = %w(
      cjaskot@brandscopic.com kkubik@brandscopic.com Elliott.Higdon@legacymp.com
      Joshua.Silverstein@legacymp.com Dan.Berliner@legacymp.com
      Alexis.Bannos@legacymp.com Christy.Sabol@legacymp.com Jordan.Lipshutz@legacymp.com
    )
    @file_name = file_name
    mail to: recipients, subject: 'Jameson Locals Accounts List Synch – Improper Format'
  end

  def success(total, existed, created, flagged_before)
    @total = total
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
