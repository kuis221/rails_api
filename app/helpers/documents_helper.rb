module DocumentsHelper
  def document_icon(file_extension)
    icon_folder = 'file-types/32px/'
    icon_filename = icon_folder + file_extension.to_s + '.png'
    unless File.exist?("#{Rails.root}/app/assets/images/#{icon_filename}")
      icon_filename = icon_folder + '_blank.png'
    end
    image_tag(icon_filename)
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