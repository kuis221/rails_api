class DocumentSerializer < ActiveModel::Serializer
  attributes :id, :name, :active, :created_at, :updated_at,
             :type, :file_name, :file_size, :content_type,
             :url, :thumbnail, :parent

  def type
    :document
  end

  def file_name
    object.file_file_name
  end

  def file_size
    object.file_file_size
  end

  def content_type
    object.file_content_type
  end

  def url
    object.download_url
  end

  def thumbnail
    object.file.url(:small)
  end

  def parent
    object.attachable_type.downcase
  end
end
