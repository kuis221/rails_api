class PhotosController < InheritedResources::Base
  respond_to :js, only: [:create, :new, :processing_status]
  respond_to :json, only: [:show]

  belongs_to :event, optional: true

  skip_load_and_authorize_resource only: [:new, :create]
  before_action :authorize_create, only: [:new, :create]

  include DeactivableController
  include PhotosHelper

  custom_actions collection: [:processing_status]

  defaults resource_class: AttachedAsset

  load_and_authorize_resource class: AttachedAsset, through: :parent, except: [:processing_status]

  def processing_status
    @photos = parent.photos.find(params[:photos])
    @photos.each do |p|
      next unless p.processing? && p.reload.processing_percentage < 90
      p.processing_percentage += 10
      # Use update_column instead of increment! to avoid calling callbacks
      # that are causing indexing issues
      p.update_column(:processing_percentage, p.processing_percentage)
    end
    @photos
  end

  protected

  def build_resource_params
    [permitted_params || {}]
  end

  def permitted_params
    params.permit(attached_asset: [:direct_upload_url])[:attached_asset]
  end

  def authorize_create
    authorize! :create_photo, parent
  end

  def return_path
    super || (if @photo
                event_path(@photo)
    else
      events_path
    end)
  end
end
