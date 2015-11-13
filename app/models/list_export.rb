# == Schema Information
#
# Table name: list_exports
#
#  id                :integer          not null, primary key
#  params            :text
#  export_format     :string(255)
#  aasm_state        :string(255)
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  company_user_id   :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  controller        :string(255)
#  progress          :integer          default(0)
#  url_options       :text
#

class ListExport < ActiveRecord::Base
  belongs_to :company_user

  has_attached_file :file, PAPERCLIP_SETTINGS

  validates_attachment_file_name :file, matches: [/xls\Z/, /pdf\Z/, /csv\Z/, /zip\Z/]

  serialize :params
  serialize :url_options

  include AASM

  View = Struct.new(:layout, :action, :locals, :format, :path)

  aasm do
    state :new, initial: true
    state :queued, after_enter: :queue_process
    state :processing
    state :completed
    state :failed

    event :queue do
      transitions from: [:new, :complete, :failed], to: :queued
    end

    event :process do
      transitions from: [:queued, :new, :failed], to: :processing
    end

    event :complete do
      transitions from: :processing, to: :completed
    end

    event :fail do
      transitions from: :processing, to: :failed
    end
  end

  def queue_process
    ListExportWorker.perform_async(id)
  end

  def download_url(style_name = :original)
    return if file_file_name.nil? || file.nil? || file.s3_object(style_name).nil?

    file.s3_bucket.objects[file.s3_object(style_name).key].url_for(
      :read,
      secure: true,
      expires: 300, # 5 minutes
      response_content_encoding: 'utf-8',
      response_content_disposition: "attachment; filename=#{file_file_name}").to_s
  end

  def export_list
    self.queue! if self.failed?
    self.process! if self.queued? || self.new?
    build_file

    # Save file or raise error if failed
    Kernel.fail(errors.full_messages.join(', ')) unless save_with_retry
    self.complete! unless self.completed?
  end

  private

  def build_file
    ctrl = load_controller
    zone = company_user.user.time_zone.presence || Rails.application.config.time_zone
    path = Dir::Tmpname.create(['export-' + id.to_s,  '.html']) {}
    Time.use_zone(zone) { ctrl.send(:export_list, self, path) }

    build_file_from_path path, "#{ctrl.send(:export_file_name)}-#{id}.#{export_format}"
  ensure
    unload_controller
  end

  def export
    Time.use_zone(zone)
  end

  def save_html_export(path)
    FileUtils.cp path, "tmp/export-#{controller.underscore.gsub('/', '-')}.html"
  end

  def build_file_from_path(path, name)
    if export_format == 'pdf'
      build_pdf_file(path)
    elsif export_format == 'zip'
      build_zip_file(path)
    else
      build_xlsx_file(path)
    end
    self.file_file_name = name
  end

  def build_zip_file(path)
    self.file = File.open(path)
    self.file_content_type = 'application/octet-stream'
  end

  def build_xlsx_file(path)
    self.file = File.open(path)
    self.file_content_type = export_format == 'csv' ? 'text/csv' : 'application/vnd.ms-excel'
  end

  # Builds a PDF file from an
  def build_pdf_file(path)
    controller_name = controller.underscore.gsub('/', '-')
    tempfile = Tempfile.new(["export-#{controller_name}", '.pdf'], Rails.root.join('tmp'))
    tempfile.binmode
    tempfile.write pdf_from_html_file(path)
    tempfile.close

    save_html_export path if Rails.env.development?
    self.file = File.open(tempfile.path)
    self.file_content_type = 'application/pdf'
  end

  def load_controller
    @controller ||= controller.constantize.new.tap do |ctrl|
      User.current = company_user.user
      Company.current = company_user.user.current_company = company_user.company
      ensure_user_has_authentication_token
      ctrl.instance_variable_set(:@_params, params)
      ctrl.instance_variable_set(:@_headers, {})
      ctrl.instance_variable_set(:@_current_user, company_user.user)
      ctrl.instance_variable_set(:@current_user, company_user.user)
      ctrl.instance_variable_set(:@current_company, company_user.company)
      ctrl.instance_variable_set(:@current_company_user, company_user)
      ctrl.instance_variable_set(:@_url_options, url_options)
    end
  end

  def unload_controller
    @controller = nil
    User.current = nil
    Company.current = nil
  end

  def pdf_from_html_file(path)
    WickedPdf.new.pdf_from_html_file(
      path,
      javascript_delay: 1000,
      # header: { content: load_controller.render_to_string(template: 'shared/pdf_header.pdf.slim') },
      extra: '--window-status completed '\
             '--debug-javascript '\
             '--custom-header Origin * '\
             "--custom-header X-User-Email #{User.current.email} "\
             "--custom-header X-Auth-Token #{User.current.authentication_token} "\
             '--custom-header-propagation')
  end

  # Checks that the user have an authentication_token
  # so ajax requests work as expected
  def ensure_user_has_authentication_token
    return unless User.current.authentication_token.nil?

    User.current.ensure_authentication_token
    User.current.save
  end

  # Retry save if it fails for network issues
  def save_with_retry
    tries ||= 3
    save

  rescue Errno::ECONNRESET, Net::ReadTimeout, Net::OpenTimeout => e
    raise e if tries == 0
    tries -= 1
    sleep(3)
    retry
  end
end
