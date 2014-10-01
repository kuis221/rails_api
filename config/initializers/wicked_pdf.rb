wkhtmltopdf_path = if Rails.env.production? || ENV['CI']
                     Rails.root.join('bin', 'wkhtmltopdf').to_s
elsif ENV['WKHTMLTOPDF_PATH']
                     ENV['WKHTMLTOPDF_PATH']
elsif /darwin/ =~ RUBY_PLATFORM then
                     '/usr/local/bin/wkhtmltopdf'
elsif /linux/ =~ RUBY_PLATFORM then
                     '/usr/bin/wkhtmltopdf'
else
  Rails.logger.debug "\n\n **** WARNING: wkhtmltopdf NOT FOUND. PDF exports will not work ****\n\n"
end

WickedPdf.config = {
  wkhtmltopdf: wkhtmltopdf_path,
  #:layout => "pdf.html",
  exe_path: wkhtmltopdf_path
}
