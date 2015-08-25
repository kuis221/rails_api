class AttachedAssetSerializer < ActiveModel::Serializer
  attributes :id, :file_file_name, :file_file_size, :file_content_type,
             :created_at, :active, :file_small, :file_thumbnail, :file_medium,
             :file_original, :processed

  def file_small
    object.processed? ? object.file.url(:small) : nil
  end

  def file_thumbnail
    object.processed? ? object.file.url(:thumbnail) : nil
  end

  def file_medium
    object.processed? ? object.file.url(:medium) : nil
  end

  def file_original
    object.file.url
  end

  def processed
    object.processed?
  end
end
