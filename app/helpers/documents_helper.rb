module DocumentsHelper
  def document_icon(document)
    file_extension = document.file_extension.to_s.downcase
    file_extension = 'jpg' if file_extension == 'jpeg'
    if %w(jpg png gif).include?(file_extension)
      image_preview_tag(document)
    else
      content_tag(:span, ".#{file_extension}", class: "document-icon #{file_extension}")
    end
  end

  def image_preview_tag(document)
    image =
      if document.processed?
        document.file.url(:small)
      else
        document.file.url
      end
    content_tag(:div, nil,
                class: 'document-image-preview',
                style: "background-image: url(#{image})")
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
