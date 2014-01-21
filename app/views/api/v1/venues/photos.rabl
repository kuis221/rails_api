collection @photos

node do |photo|
  if photo.is_a?(AttachedAsset)
    node(:type) { :brandscopic }
    partial "api/v1/photos/photo", :object => photo
  else
    node(:type) { :google }
    partial "api/v1/photos/google", :object => OpenStruct.new(photo)
  end
end