# == Schema Information
#
# Table name: reports
#
#  id                :integer          not null, primary key
#  type              :string(255)
#  company_user_id   :integer
#  params            :text
#  aasm_state        :string(255)
#  progress          :integer
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Report < ActiveRecord::Base
  include AASM

  has_attached_file :file, PAPERCLIP_SETTINGS

  belongs_to :company_user

  serialize :params

  aasm do
    state :new, :initial => true
    state :queued, :enter => :queue_report
    state :processing
    state :complete, :enter => :progress_complete
    state :failed

    event :queue do
      transitions :from => :new, :to => :queued
    end

    event :process do
      transitions :from => :queued, :to => :processing
    end

    event :succeed do
      transitions :from => :processing, :to => :complete
    end

    event :fail do
      transitions :from => [:queued, :processing, :complete, :failed], :to => :failed
    end

    event :regenerate do
      transitions :from => [:queued, :processing, :complete, :failed], :to => :queued, :before => :destroy_report
    end
  end

  def download_url(style_name=:original)
    file.s3_bucket.objects[file.s3_object(style_name).key].url_for(:read,
      :secure => true,
      :response_content_disposition => "attachment; filename=#{file_file_name}").to_s
  end

  def generate_report
    return unless queued?
    self.process!
    self.file = StringIO.new(report_output)
    self.file_file_name = object_name
    self.file_content_type = 'text/csv'
    self.save
    self.succeed!
    rescue Exception => e
      self.fail!
      raise e
  end

  # This method should be implemented by the child class
  def report_output
    ''
  end

  def object_name
    "#{self.type.parameterize}-#{company_user.full_name.parameterize}-#{created_at.to_s.parameterize}.csv"
  end

  private

    def queue_report
      set_progress(0)
      Resque.enqueue ReportWorker, self.id
    end

    def progress_complete
      set_progress(100)
    end

    def set_progress(progress)
      unless progress.nil?
        progress = [[progress, 100].min, 0].max unless progress.nil?
        self.update_column(:progress, progress)
      end
    end

    def show_progress(completed, total)
      progress = completed*100/total rescue 0         # rescue from divide by zero
      set_progress(progress)
    end
end
