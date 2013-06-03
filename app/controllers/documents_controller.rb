class DocumentsController < FilteredController
  include TeamMembersHelper

  respond_to :js, only: [:new, :create, :edit, :update, :show, :destroy]
  belongs_to :event

  load_and_authorize_resource :event
  load_and_authorize_resource through: :event

  protected
    def collection_to_json
      collection.map{|document| {
        :id => document.id,
        :name => document.name,
        :level => document.documentable_type,
        :type => File.extname(document.file_file_name)[1..-1].upcase,
        :links => {
            delete: event_document_path(parent, document)
        }
      }}
    end

    def sort_options
      {
        'name' => { :order => 'documents.name' },
        'level' => { :order => 'documents.documentable_type' }
      }
    end

end
