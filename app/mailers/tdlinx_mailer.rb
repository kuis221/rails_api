class TdlinxMailer < ActionMailer::Base
  default from: 'noreply@brandscopic.com'

  def td_linx_process_completed(file_path)
    to = ENV['TDLINX_SUCCESS_EMAIL'] || 'gvargas@brandscopic.com'
    attachments['tdlinx_results.zip'] = File.read(file_path)
    mail(to: to, subject: 'TD Linx Process Completed')
  end

  def td_linx_process_failed(e)
    @exception = e
    to = ENV['TDLINX_ERROR_EMAIL'] || 'gvargas@brandscopic.com'
    mail(to: 'gvargas@brandscopic.com', subject: 'TD Linx Process FAILED')
  end
end
