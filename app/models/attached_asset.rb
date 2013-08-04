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
#

class AttachedAsset < ActiveRecord::Base
  track_who_does_it

  belongs_to :attachable, :polymorphic => true
  has_attached_file :file, PAPERCLIP_SETTINGS
  attr_accessible :file, :asset_type

  before_post_process :image?

  validates_attachment_presence :file

  searchable do
    string :status
    string :asset_type
    string :attachable_type

    string :file_file_name
    integer :file_file_size

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
    string :place do
      Place.location_for_index(attachable.place) if attachable_type == 'Event' && attachable.place_id
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

    string :location, multiple: true do
      attachable.locations_for_index if attachable_type == 'Event'
    end
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def status
    self.active? ? 'Active' : 'Inactive'
  end

  def file_extension(filename)
    File.extname(filename)[1..-1]
  end

  def download_url(style_name=:original)
    s3 = AWS::S3.new
    @bucket ||= s3.buckets[file.bucket_name]
    @bucket.objects[file.s3_object(style_name).key].url_for(:read,
      :secure => true,
      :expires => 24*3600, # 24 hours
      :response_content_disposition => "attachment; filename=#{file_file_name}").to_s
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      solr_search do
        with(:company_id, params[:company_id])
        if params[:start_date].present? and params[:end_date].present?
          d1 = Timeliness.parse(params[:start_date], zone: :current).beginning_of_day
          d2 = Timeliness.parse(params[:end_date], zone: :current).end_of_day
          with :start_at, d1..d2
        elsif params[:start_date].present?
          d = Timeliness.parse(params[:start_date], zone: :current)
          with :start_at, d.beginning_of_day..d.end_of_day
        end
        with(:campaign_id, params[:campaign]) if params.has_key?(:campaign) and params[:campaign].present?
        with(:place_id, params[:place_id]) if params.has_key?(:place_id) and params[:place_id].present?
        with(:asset_type, params[:asset_type]) if params.has_key?(:asset_type) and params[:asset_type].present?
        with(:status, params[:status]) if params.has_key?(:status) and params[:status].present?
        if params.has_key?(:brand) and params[:brand].present?
          with "campaign_id", Campaign.select('campaigns.id').joins(:brands).where(brands: {id: params[:brand]}).map(&:id)
        end
        if params.has_key?(:place) and params[:place].present?
          place_paths = []
          params[:place].each do |place|
            # The location comes BASE64 encoded as a pair "id||name"
            # The ID is a md5 encoded string that is indexed on Solr
            (id, name) = Base64.decode64(place).split('||')
            place_paths.push id
          end
          if place_paths.size > 0
            with(:location, place_paths)
          end
        end

        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'brand'
            campaigns = Campaign.select('campaigns.id').joins(:brands).where(brands: {id: value}).map(&:id)
            campaigns = '-1' if campaigns.empty?
            with "campaign_id", campaigns
          when 'campaign', 'place'
            with "#{attribute}_id", value
          else
            with "#{attribute}_ids", value
          end
        end

        if include_facets
          facet :campaign
          facet :place
          facet :status
        end

        order_by(params[:sorting] || :created_at, params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end
  end

  private
    def image?
      !(file_content_type =~ /^image.*/).nil?
    end

end
