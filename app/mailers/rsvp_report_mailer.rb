class RsvpReportMailer < ActionMailer::Base
  default from: 'support@brandscopic.com'

  def file_missing
    recipients = %w(
      cjaskot@brandscopic.com kkubik@brandscopic.com Elliott.Higdon@legacymp.com
      Joshua.Silverstein@legacymp.com Dan.Berliner@legacymp.com Alexis.Bannos@legacymp.com
      Christy.Sabol@legacymp.com
    )
    mail to: recipients, subject: 'RSVP Report Synch – File Not Found'
  end

  def invalid_format(files)
    recipients = %w(
      cjaskot@brandscopic.com kkubik@brandscopic.com Elliott.Higdon@legacymp.com
      Joshua.Silverstein@legacymp.com Dan.Berliner@legacymp.com Alexis.Bannos@legacymp.com
      Christy.Sabol@legacymp.com
    )
    files.each do |path|
      attachments[File.basename(path)] = File.read(path)
    end
    mail to: recipients, subject: 'RSVP Report Synch – Improper Format'
  end

  def success(created, failed, files = [])
    @created = created
    @failed = failed
    recipients = %w(
      cjaskot@brandscopic.com kkubik@brandscopic.com Elliott.Higdon@legacymp.com
      Joshua.Silverstein@legacymp.com Dan.Berliner@legacymp.com Alexis.Bannos@legacymp.com
      Christy.Sabol@legacymp.com  Jordan.Lipshutz@legacymp.com
    )

    files.each do |path|
      attachments[File.basename(path)] = File.read(path)
    end

    mail to: recipients, subject: 'RSVP Report Synch – Successfully Completed'
  end
end
