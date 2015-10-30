# == Schema Information
#
# Table name: attached_assets
#
#  id                    :integer          not null, primary key
#  file_file_name        :string(255)
#  file_content_type     :string(255)
#  file_file_size        :integer
#  file_updated_at       :datetime
#  asset_type            :string(255)
#  attachable_id         :integer
#  attachable_type       :string(255)
#  created_by_id         :integer
#  updated_by_id         :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  active                :boolean          default(TRUE)
#  direct_upload_url     :string(255)
#  rating                :integer          default(0)
#  folder_id             :integer
#  status                :integer          default(0)
#  processing_percentage :integer          default(0)
#

class AttachedAsset < ActiveRecord::Base
  # Defines the method do_search
  include SolrSearchable
  include EventBaseSolrSearchable

  track_who_does_it
  has_and_belongs_to_many :tags, -> { order 'name ASC' },
                          autosave: true,
                          after_add: ->(asset, _) { asset.index },
                          after_remove:  ->(asset, _) { asset.index }
  DIRECT_UPLOAD_URL_FORMAT = %r{\Ahttps:\/\/s3\.amazonaws\.com\/#{ENV['S3_BUCKET_NAME']}\/(?<path>uploads\/.+\/(?<filename>.+))\z}.freeze
  belongs_to :attachable, polymorphic: true
  belongs_to :folder, class_name: 'DocumentFolder'

  attr_accessor :new_name

  enum status: { queued: 0, processing: 1, processed: 2,  failed: 3 }

  has_attached_file :file,
                    PAPERCLIP_SETTINGS.merge(
                      styles: ->(a) do
                        if a.instance.pdf?
                          a.options[:convert_options] = {
                            thumbnail: '-quality 85 -strip -gravity north -thumbnail 300x400^ -extent 300x400'
                          }
                          { thumbnail: ['300x400>', :jpg] }
                        else
                          { small: '', thumbnail: '', medium: '800x800>' }
                        end
                      end,
                      processors: ->(instance) { instance.pdf? ? [:ghostscript, :thumbnail] : [:thumbnail] },
                      convert_options: {
                        small: '-quality 85 -strip -gravity north -thumbnail 180x180^ -extent 180x120',
                        thumbnail: '-quality 85 -strip -gravity north -thumbnail 400x400^ -extent 400x267',
                        medium: '-quality 85 -strip'
                      }
                    )

  do_not_validate_attachment_file_type :file

  scope :for_events, ->(events) { where(attachable_type: 'Event', attachable_id: events) }
  scope :photos, -> { where(asset_type: 'photo') }
  scope :active, -> { where(active: true) }

  validate :valid_file_format?

  before_validation :set_upload_attributes

  after_commit :queue_processing
  after_save :update_active_photos_count, if: -> { attachable.is_a?(Event) && self.photo? }
  after_destroy :update_active_photos_count, if: -> { attachable.is_a?(Event) && self.photo? }
  after_update :rename_existing_file, if: :processed?
  before_post_process :post_process_required?

  validates :attachable, presence: true

  validates :direct_upload_url, allow_nil: true, on: :create,
                                uniqueness: true,
                                format: { with: DIRECT_UPLOAD_URL_FORMAT }
  validates :direct_upload_url, presence: true, unless: :file_file_name

  validate :max_event_photos, on: :create, if: proc { |a| a.attachable.is_a?(Event) && a.photo? }

  delegate :company_id, :update_active_photos_count, to: :attachable

  searchable if: proc { |asset| asset.attachable_type == 'Event' }  do
    string :status
    string :asset_type
    string :attachable_type

    string :file_file_name
    integer :file_file_size
    boolean :processed do
      processed?
    end

    integer :event_id do
      attachable_id
    end

    boolean :active

    string :tag, multiple: true do
      tags.pluck(:id)
    end
    integer :rating
    time :created_at

    join(:location, target: Event, type: :integer, join: { from: :id, to: :event_id }, as: :location_im)
    join(:place_id, target: Event, type: :integer, join: { from: :id, to: :event_id }, as: :place_id_i)
    join(:company_id, target: Event, type: :integer, join: { from: :id, to: :event_id }, as: :company_id_i)
    join(:user_ids, target: Event, type: :integer, join: { from: :id, to: :event_id }, as: :user_ids_im)
    join(:team_ids, target: Event, type: :integer, join: { from: :id, to: :event_id }, as: :team_ids_im)
    join(:campaign_id, target: Event, type: :integer, join: { from: :id, to: :event_id }, as: :campaign_id_is)
    join(:start_at, target: Event, type: :time, join: { from: :id, to: :event_id }, as: :start_at_dts)
    join(:end_at, target: Event, type: :time, join: { from: :id, to: :event_id }, as: :end_at_dts)
    join(:local_start_at, target: Event, type: :time, join: { from: :id, to: :event_id }, as: :local_start_at_dts)
    join(:local_end_at, target: Event, type: :time, join: { from: :id, to: :event_id }, as: :local_end_at_dts)
  end

  def activate!
    update_attribute :active, true
  end

  def name
    file_file_name.gsub("\.#{file_extension}", '')
  end

  def deactivate!
    update_attribute :active, false
  end

  def status
    self.active? ? 'Active' : 'Inactive'
  end

  def file_extension
    File.extname(file_file_name)[1..-1] if file_file_name
  end

  # Store an unescaped version of the escaped URL that Amazon returns from direct upload.
  def direct_upload_url=(escaped_url)
    write_attribute(:direct_upload_url, (CGI.unescape(escaped_url) rescue nil))
  end

  def download_url(style_name = :original)
    file.s3_bucket.objects[file.s3_object(style_name).key]
      .url_for(
        :read, secure: true,
               force_path_style: true,
               expires: 24 * 3600, # 24 hours
               response_content_disposition: "attachment; filename=#{file_file_name}").to_s
  end

  def preview_url(style_name = :medium, opts = {})
    if pdf?
      file.url(:thumbnail, opts)
    else
      file.url(style_name, opts)
    end
  end

  def is_thumbnable?
    %r{^(image|(x-)?application)/(bmp|gif|jpeg|jpg|pjpeg|png|x-png|pdf)$}.match(file_content_type).present?
  end

  def pdf?
    %r{^(x-)?application/pdf$}.match(file_content_type).present?
  end

  class << self
    def compress(ids)
      assets_ids = ids.sort.map(&:to_i)
      download = AssetDownload.find_or_create_by_assets_ids(assets_ids, assets_ids: assets_ids)
      download.queue! if download.new?
      download
    end
  end

  # Moving the original file to final path
  def move_uploaded_file
    direct_upload_url_data = DIRECT_UPLOAD_URL_FORMAT.match(direct_upload_url)
    paperclip_file_path = file.path(:original).sub(/\A\//, '')
    return if file.s3_bucket.objects[paperclip_file_path].exists? ||
              !file.s3_bucket.objects[direct_upload_url_data[:path]].exists?
    file.s3_bucket.objects[paperclip_file_path].copy_from(
      direct_upload_url_data[:path], acl: :public_read)
  end

  def self.copy_file_to_uploads_folder(url)
    path = CGI.unescape(URI.parse(URI.encode(url)).path.gsub("/#{ENV['S3_BUCKET_NAME']}/", ''))
    paperclip_file_path = "uploads/#{Time.now.to_i}-#{rand(5000)}/#{File.basename(path)}"
    AWS::S3.new.buckets[ENV['S3_BUCKET_NAME']].objects[paperclip_file_path].copy_from(
      path, acl: :public_read)
    "https://s3.amazonaws.com/#{ENV['S3_BUCKET_NAME']}/#{paperclip_file_path}"
  rescue AWS::S3::Errors::NoSuchKey
    nil
  end

  # Rename existing file in S3
  def rename_existing_file
    return unless file_file_name_changed?

    (file.styles.keys + [:original]).each do |style|
      dirname = File.dirname(file.path(style).sub(/\A\//, ''))
      old_path = "#{dirname}/#{file_file_name_was}"
      new_path = "#{dirname}/#{file_file_name}"
      begin
        file.s3_bucket.objects[old_path].move_to(new_path, acl: :public_read)
      rescue AWS::S3::Errors::NoSuchKey
      end
    end
  end

  # Final upload processing step
  def transfer_and_cleanup
    processing!
    if post_process_required?
      file.reprocess!
    end
    self.processing_percentage = 100

    direct_upload_url_data = DIRECT_UPLOAD_URL_FORMAT.match(direct_upload_url)
    file.s3_bucket.objects[direct_upload_url_data[:path]].delete if save
    processed!
  end

  def photo?
    asset_type == 'photo'
  end

  protected

  def valid_file_format?
    return unless asset_type.to_s == 'photo'
    if /\A(image|(x-)?application)\/(bmp|gif|jpeg|jpg|pjpeg|png|x-png)\z/.match(file_content_type).nil?
      errors.add(:file, 'is not valid format')
    end
  end

  # Determines if file requires post-processing (image resizing, etc)
  def post_process_required?
    is_thumbnable?
  end

  # Set attachment attributes from the direct upload
  # @note Retry logic handles S3 "eventual consistency" lag.
  def set_upload_attributes
    tries ||= 3
    direct_url_changed = direct_upload_url.present? && self.direct_upload_url_changed?
    if ((new_record? && file_file_name.nil?) || direct_url_changed) && direct_upload_url_data = DIRECT_UPLOAD_URL_FORMAT.match(direct_upload_url)
      direct_upload_head = file.s3_bucket.objects[direct_upload_url_data[:path]].head

      self.file_file_name     = file.send(:cleanup_filename, direct_upload_url_data[:filename])
      self.file_file_size     = direct_upload_head.content_length
      self.file_content_type  = direct_upload_head.content_type
      self.file_updated_at    = direct_upload_head.last_modified

      if file_content_type == 'binary/octet-stream'
        self.file_content_type = MIME::Types.type_for(file_file_name).first.to_s
      end
    end
  rescue Errno::ECONNRESET, Net::ReadTimeout, Net::ReadTimeout => e
    tries -= 1
    if tries > 0
      sleep(1)
      retry
    else
      self.fail!
      raise e
    end
  rescue AWS::S3::Errors::NoSuchKey
  end

  # Queue file processing
  def queue_processing
    return if !queued? || direct_upload_url.nil?

    move_uploaded_file
    if post_process_required?
      AssetsUploadWorker.perform_async(id, self.class.name)
    else
      transfer_and_cleanup
    end
    true
  end

  def max_event_photos
    return true unless attachable.campaign.range_module_settings?('photos')
    max = attachable.campaign.module_setting('photos', 'range_max')
    return true if max.blank? || attachable.photos.active.count < max.to_i
    errors.add(:base, I18n.translate('instructive_messages.execute.photo.add_exceeded', count: max.to_i))
  end
end
