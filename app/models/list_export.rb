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
#

class ListExport < ActiveRecord::Base
  belongs_to :company_user

  has_attached_file :file, PAPERCLIP_SETTINGS

  serialize :params

  include AASM

  aasm do
    state :new, :initial => true
    state :queued, before_enter: :queue_process
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
      :response_content_disposition => "attachment; filename=#{file_file_name}").to_s
  end

  def export_list
    self.process!
    controller = self.controller.constantize.new

    User.current = company_user.user
    controller.instance_variable_set(:@_current_user, company_user.user)
    controller.instance_variable_set(:@current_company, company_user.company)

    name = controller.send(:export_file_name)
    buffer = controller.send(:export_list, self)
    tmp_filename = "#{Rails.root}/tmp/#{name}.#{export_format}"
    output_file = File.open(tmp_filename, 'w'){|f| f.write(buffer) }
    self.file = File.open(tmp_filename)
    self.save

    # Mark export as completed
    self.complete!
  end
end
