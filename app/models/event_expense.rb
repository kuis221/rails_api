# == Schema Information
#
# Table name: event_expenses
#
#  id                :integer          not null, primary key
#  event_id          :integer
#  name              :string(255)
#  amount            :decimal(9, 2)    default(0.0)
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  created_by_id     :integer
#  updated_by_id     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class EventExpense < ActiveRecord::Base
  belongs_to :event
  attr_accessible :amount, :file, :name

  has_attached_file :file, PAPERCLIP_SETTINGS.merge({
    :styles => { :small => { :geometry => '135',  :format => :png }, :medium => { :geometry => '400',  :format => :png } },
  })
  before_post_process :image?

  #validates :event_id, presence: true, numericality: true
  validates :name, presence: true

  after_save :update_event_data

  delegate :company_id, to: :event

  def download_url(style_name=:original)
    s3 = AWS::S3.new
    @bucket ||= s3.buckets[file.bucket_name]
    @bucket.objects[file.s3_object(style_name).key].url_for(:read,
      :secure => true,
      :expires => 24*3600, # 24 hours
      :response_content_disposition => "attachment; filename=#{file_file_name}").to_s
  end

  private
     def update_event_data
        Resque.enqueue(EventDataIndexer, event.event_data.id) if event.event_data.present?
     end

    def image?
      !(file_content_type =~ %r{^(image|(x-)?application)/(x-png|pjpeg|jpeg|jpg|png|gif|pdf)$}).nil?
    end
end
