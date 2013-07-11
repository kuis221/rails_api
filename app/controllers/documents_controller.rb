class DocumentsController < FilteredController
  include TeamMembersHelper

  respond_to :js, only: [:new, :create, :edit, :update, :show, :destroy]
  belongs_to :event

  load_and_authorize_resource :event
  load_and_authorize_resource through: :event

  protected

    def sort_options
      {
        'name' => { :order => 'documents.name' },
        'level' => { :order => 'documents.documentable_type' }
      }
    end

end
