class DocumentsController < InheritedResources::Base
  respond_to :js, only: [:new, :create, :edit, :update, :show]
  belongs_to :event

  load_and_authorize_resource :event
  load_and_authorize_resource through: :event

  respond_to_datatables do
    columns [
      {:attr => :name, :column_name => 'documents.name'},
      {:attr => :documentable_type, :column_name => 'documents.documentable_type'},
      {:attr => :file_content_type, :column_name => 'documents.file_content_type' }
    ]
    @editable  = false
    @deactivable = false
  end

end
