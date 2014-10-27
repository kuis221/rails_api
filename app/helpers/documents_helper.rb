module DocumentsHelper
  def document_icon(file_extension)
    icon_folder = 'file-types/32px/'
    file_extension = file_extension.to_s.downcase
    file_extension = 'jpg' if file_extension == 'jpeg'
    content_tag(:span, ".#{file_extension}", class: "document-icon #{file_extension}")
  end

  def document_type(document)
    if document.file_content_type.match(/\Aimage/)
      'Image'
    else
      'Document'
    end
  end

  def folder_parents(folder)
    parents = []
    parent = folder
    while parent = parent.parent
      parents.push parent
    end
    parents.reverse!
  end
end
