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

  do_not_validate_attachment_file_type :file

  serialize :params
  serialize :url_options

  include AASM

  View = Struct.new(:layout, :action, :locals, :format, :path)

  aasm do
    state :new, :initial => true
    state :queued, after_enter: :queue_process
    state :processing
    state :completed
    state :failed

    event :queue do
      transitions :from => [:new, :complete, :failed], :to => :queued
    end

    event :process do
      transitions :from => [:queued, :new, :failed], :to => :processing
    end

    event :complete do
      transitions :from => :processing, :to => :completed
    end

    event :fail do
      transitions :from => :processing, :to => :failed
    end
  end

  def queue_process
    Resque.enqueue(ListExportWorker, self.id)
  end

  def download_url(style_name=:original)
    file.s3_bucket.objects[file.s3_object(style_name).key].url_for(:read,
      :secure => true,
      :expires => 300, # 5 minutes
      :response_content_disposition => "attachment; filename=#{file_file_name}").to_s unless file_file_name.nil? || file.nil? || file.s3_object(style_name).nil?
  end

  def export_list
    self.process! if self.queued? || self.new?
    controller = self.controller.constantize.new

    User.current = company_user.user
    Company.current = company_user.user.current_company = company_user.company

    # So ajax requests work as expected
    if User.current.authentication_token.nil?
      User.current.ensure_authentication_token
      User.current.save
    end

    controller.instance_variable_set(:@_params, params)
    controller.instance_variable_set(:@_current_user, company_user.user)
    controller.instance_variable_set(:@current_user, company_user.user)
    controller.instance_variable_set(:@current_company, company_user.company)
    controller.instance_variable_set(:@current_company_user, company_user)
    controller.instance_variable_set(:@_url_options, url_options.merge(only_path: false, auth_token: User.current.authentication_token))

    if company_user.user.time_zone.present?
      Time.zone = company_user.user.time_zone
    end

    name = controller.send(:export_file_name)
    if export_format == 'pdf'
      html = controller.send(:export_list, self)

      if Rails.env.development?
        tempfile = Tempfile.new(["export-#{self.controller.underscore.gsub('/', '-')}", ".html"], Rails.root.join('tmp'))
        tempfile.write html
        tempfile.close
      end

      tempfile = Tempfile.new(["export-#{self.controller.underscore.gsub('/', '-')}", ".pdf"], Rails.root.join('tmp'))
      tempfile.binmode
      tempfile.write(WickedPdf.new.pdf_from_string(html,
        javascript_delay: 1000,
        header: { content: controller.render_to_string(template: 'shared/pdf_header.pdf.slim') },
        extra: '--window-status completed --debug-javascript'))
      tempfile.close

      self.file = File.open(tempfile.path)
      self.file_content_type = "application/pdf"
    else
      self.file = StringIO.new(controller.send(:export_list, self))
    end
    self.file_file_name = "#{name}-#{self.id}.#{export_format}"

    # Save export with retry to handle errors on S3 comunications
    tries = 3
    begin
      self.save
    rescue Exception => e
      tries -= 1
      if tries > 0
        sleep(3)
        retry
      else
        false
      end
    end
    # Mark export as completed
    self.complete! unless self.completed?
  end
end
