class VenuePhotoSerializer < ActiveModel::Serializer
  attributes :id, :file_file_name, :file_file_size, :file_content_type,
             :created_at, :active, :file_small, :file_thumbnail, :file_medium,
             :file_original, :processed

  def file_small
    if object.is_a?(AttachedAsset)
      object.processed? ? object.file.url(:small) : nil
    else
      "https://maps.googleapis.com/maps/api/place/photo?maxwidth=180&photoreference=#{photo.photo_reference}&sensor=true&key=#{GOOGLE_API_KEY}"
    end
  end

  def file_thumbnail
    if object.is_a?(AttachedAsset)
      object.processed? ? object.file.url(:thumbnail) : nil
    else
      "https://maps.googleapis.com/maps/api/place/photo?maxwidth=180&photoreference=#{photo.photo_reference}&sensor=true&key=#{GOOGLE_API_KEY}"
    end
  end

  def file_medium
    if object.is_a?(AttachedAsset)
      object.processed? ? object.file.url(:medium) : nil
    else
      "https://maps.googleapis.com/maps/api/place/photo?maxheight=700&maxwidth=700&photoreference=#{photo.photo_reference}&sensor=true&key=#{GOOGLE_API_KEY}"
    end
  end

  def file_original
    if object.is_a?(AttachedAsset)
      object.processed? ? object.file.url : nil
    else
      "https://maps.googleapis.com/maps/api/place/photo?maxheight=700&maxwidth=700&photoreference=#{photo.photo_reference}&sensor=true&key=#{GOOGLE_API_KEY}"
    end
  end

  def processed
    object.processed? if object.is_a?(AttachedAsset)
  end

  def photo_reference
    object.photo_reference unless object.is_a?(AttachedAsset)
  end
end
