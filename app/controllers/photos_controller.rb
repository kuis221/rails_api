class PhotosController < FilteredController

  respond_to :js, only: :create
  belongs_to :event, optional: true

end