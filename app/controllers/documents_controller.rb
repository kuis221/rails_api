class DocumentsController < FilteredController

  respond_to :js, only: [:new, :create, :edit, :update, :show, :destroy]
  belongs_to :event

end