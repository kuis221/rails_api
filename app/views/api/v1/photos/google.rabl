attributes :photo_reference, :width, :height, :html_attributions

node :file_small do |photo|
  "https://maps.googleapis.com/maps/api/place/photo?maxwidth=180&photoreference=#{photo.photo_reference}&sensor=true&key=#{GOOGLE_API_KEY}"
end

node :file_original do |photo|
  "https://maps.googleapis.com/maps/api/place/photo?maxheight=700&maxwidth=700&photoreference=#{photo.photo_reference}&sensor=true&key=#{GOOGLE_API_KEY}"
end