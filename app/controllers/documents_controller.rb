class DocumentsController < InheritedResources::Base
  respond_to :js, only: [:new, :create, :edit, :update, :show, :destroy]
  belongs_to :event, :optional => true

  load_and_authorize_resource :event
  load_and_authorize_resource through: :event

  respond_to_datatables do
    columns [
      {:attr => :name, :column_name => 'documents.name', :value => Proc.new{|document| @controller.view_context.link_to(document.name, document.download_url)}},
      {:attr => :documentable_type, :column_name => 'documents.documentable_type'},
      {:attr => :file_file_name, :column_name => 'documents.file_file_name', :value => Proc.new{|document| File.extname(document.file_file_name)[1..-1].upcase}}
    ]
    @editable  = false
    @deactivable = false
    @deletable = true
  end
end
