# == Schema Information
#
# Table name: attached_assets
#
#  id                :integer          not null, primary key
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  asset_type        :string(255)
#  attachable_id     :integer
#  attachable_type   :string(255)
#  created_by_id     :integer
#  updated_by_id     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  active            :boolean          default(TRUE)
#  direct_upload_url :string(255)
#  processed         :boolean          default(FALSE), not null
#  rating            :integer          default(0)
#

class AttachedAsset < ActiveRecord::Base
  track_who_does_it
  has_and_belongs_to_many :tags, :order => 'name ASC', :autosave => true
  DIRECT_UPLOAD_URL_FORMAT = %r{\Ahttps:\/\/s3\.amazonaws\.com\/#{S3_CONFIGS['bucket_name']}\/(?<path>uploads\/.+\/(?<filename>.+))\z}.freeze
  belongs_to :attachable, :polymorphic => true
  has_attached_file :file, PAPERCLIP_SETTINGS.merge({
    :styles => {
      :small => '',
      :thumbnail => '',
      :medium => '800x800>'
    },
    :convert_options => {
      :small => '-quality 85 -strip -gravity north -thumbnail 180x180^ -extent 180x120',
      :thumbnail => '-quality 85 -strip -gravity north -thumbnail 400x400^ -extent 400x267',
      :medium => '-quality 85 -strip'
    }
  })

  scope :for_events, lambda{|events| where(attachable_type: 'Event', attachable_id: events) }
  scope :photos, lambda{ where(asset_type: 'photo') }
  scope :active, lambda{ where(active: true) }

  validate :valid_file_format?

  before_validation :set_upload_attributes
  after_commit :queue_processing, on: :create
  before_post_process :post_process_required?

  validates :direct_upload_url, allow_nil: true, format: { with: DIRECT_UPLOAD_URL_FORMAT }
  validates :direct_upload_url, presence: true, unless: :file

  delegate :company_id, to: :attachable

  searchable do
    string :status
    string :asset_type
    string :attachable_type

    string :file_file_name
    integer :file_file_size
    boolean :processed

    integer :attachable_id

    boolean :active

    time :created_at
    time :start_at, :trie => true do
      attachable.start_at if attachable_type == 'Event'
    end
    time :end_at, :trie => true do
      attachable.end_at if attachable_type == 'Event'
    end

    integer :company_id do
      attachable.company_id if attachable.present?
    end

    integer :place_id do
      attachable.place_id if attachable_type == 'Event'
    end
    string :place_name do
      attachable.place_name if attachable_type == 'Event'
    end

    integer :campaign_id do
      attachable.campaign_id if attachable_type == 'Event'
    end
    string :campaign do
      attachable.campaign_id.to_s + '||' + attachable.campaign_name.to_s if attachable_type == 'Event' && attachable.campaign_id
    end
    string :campaign_name do
      attachable.campaign_name if attachable_type == 'Event'
    end

    latlon(:location) do
      Sunspot::Util::Coordinates.new(attachable.place_latitude, attachable.place_latitude) if attachable_type == 'Event' && attachable.place_id
    end

    integer :location, multiple: true do
      attachable.locations_for_index if attachable_type == 'Event'
    end

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
    File.extname(file_file_name)[1..-1]
  end

  # Store an unescaped version of the escaped URL that Amazon returns from direct upload.
  def direct_upload_url=(escaped_url)
    write_attribute(:direct_upload_url, (CGI.unescape(escaped_url) rescue nil))
  end

  def download_url(style_name=:original)
    file.s3_bucket.objects[file.s3_object(style_name).key].url_for(:read,
      :secure => true,
      :expires => 24*3600, # 24 hours
      :response_content_disposition => "attachment; filename=#{file_file_name}").to_s
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      options = {include: {:attachable => [:campaign, :place] }}
      solr_search(options) do
        with :company_id, params[:company_id]
        with :processed, true

        company_user = params[:current_company_user]
        if company_user.present?
          unless company_user.role.is_admin?
            with(:campaign_id, company_user.accessible_campaign_ids + [0])
            any_of do
              locations = company_user.accessible_locations
              places_ids = company_user.accessible_places
              with(:place_id, places_ids + [0])
              with(:location, locations + [0])
            end
          end
        end

        if params[:start_date].present? and params[:end_date].present?
          d1 = Timeliness.parse(params[:start_date], zone: :current).beginning_of_day
          d2 = Timeliness.parse(params[:end_date], zone: :current).end_of_day
          with :start_at, d1..d2
        elsif params[:start_date].present?
          d = Timeliness.parse(params[:start_date], zone: :current)
          with :start_at, d.beginning_of_day..d.end_of_day
        end
        if params[:event_id].present?
          with(:attachable_id, params[:event_id])
          with(:attachable_type, 'Event')
        end
        with(:campaign_id, params[:campaign]) if params.has_key?(:campaign) and params[:campaign].present?
        with(:place_id, params[:place_id]) if params.has_key?(:place_id) and params[:place_id].present?
        with(:asset_type, params[:asset_type]) if params.has_key?(:asset_type) and params[:asset_type].present?
        with(:status, params[:status]) if params.has_key?(:status) and params[:status].present?
        if params.has_key?(:brand) and params[:brand].present?
          with "campaign_id", Campaign.select('campaigns.id').joins(:brands).where(brands: {id: params[:brand]}).map(&:id)
        end

        with(:location, params[:location]) if params.has_key?(:location) and params[:location].present?

        with(:location, Area.where(id: params[:area]).map{|a| a.locations.map(&:id) }.flatten + [0]  ) if params[:area].present?

        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'brand'
            campaigns = Campaign.select('campaigns.id').joins(:brands).where(brands: {id: value}).map(&:id)
            campaigns = '-1' if campaigns.empty?
            with "campaign_id", campaigns
          when 'campaign'
            with "#{attribute}_id", value
          when 'venue'
            with :place_id, Venue.find(value).place_id
          else
            with "#{attribute}_ids", value
          end
        end

        if include_facets
          facet :campaign
          facet :place_id
          facet :status
        end

        order_by(params[:sorting] || :created_at, params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end

    def compress(ids)
      assets_ids = ids.sort.map(&:to_i)
      download = AssetDownload.find_or_create_by_assets_ids(assets_ids, assets_ids: assets_ids)
      if download.new?
        download.queue!
      end
      download
    end
  end

  # Final upload processing step
  def transfer_and_cleanup
    direct_upload_url_data = DIRECT_UPLOAD_URL_FORMAT.match(direct_upload_url)
    s3 = AWS::S3.new

    paperclip_file_path = file.path(:original).sub(%r{\A/},'')
    s3.buckets[S3_CONFIGS['bucket_name']].objects[paperclip_file_path].copy_from(direct_upload_url_data[:path])
    if post_process_required?
      file.reprocess!
    end
    self.processed = true

    s3.buckets[S3_CONFIGS['bucket_name']].objects[direct_upload_url_data[:path]].delete if save
  end

  protected

    def valid_file_format?
      if asset_type.to_s == 'photo'
        if %r{^(image|(x-)?application)/(bmp|gif|jpeg|jpg|pjpeg|png|x-png)$}.match(file_content_type).nil?
          errors.add(:file, 'is not valid format')
        end
      end
    end

    # Determines if file requires post-processing (image resizing, etc)
    def post_process_required?
      %r{^(image|(x-)?application)/(bmp|gif|jpeg|jpg|pjpeg|png|x-png)$}.match(file_content_type).present?
    end

    # Set attachment attributes from the direct upload
    # @note Retry logic handles S3 "eventual consistency" lag.
    def set_upload_attributes
      if new_record? and self.file_file_name.nil?
        direct_upload_url_data = DIRECT_UPLOAD_URL_FORMAT.match(direct_upload_url)
        s3 = AWS::S3.new
        direct_upload_head = s3.buckets[S3_CONFIGS['bucket_name']].objects[direct_upload_url_data[:path]].head

        self.file_file_name     = file.send(:cleanup_filename, direct_upload_url_data[:filename])
        self.file_file_size     = direct_upload_head.content_length
        self.file_content_type  = direct_upload_head.content_type
        self.file_updated_at    = direct_upload_head.last_modified

        if self.file_content_type == 'binary/octet-stream'
          self.file_content_type = MIME::Types.type_for(self.file_file_name).first.to_s
        end
      end
    end

    # Queue file processing
    def queue_processing
      unless processed?
        if direct_upload_url.present?
          if post_process_required?
            Resque.enqueue(AssetsUploadWorker, id)
          else
            transfer_and_cleanup
          end
        end
      end
    end

end
