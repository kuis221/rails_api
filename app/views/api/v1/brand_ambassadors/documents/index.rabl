collection @folder_children

attributes :id, :name, :updated_at

node :type do |doc|
  if doc.is_a?(BrandAmbassadors::Document)
  	:document
  else
  	:folder
  end
end

node :file_name do |doc|
  doc.file_file_name if doc.is_a?(BrandAmbassadors::Document)
end

node :content_type do |doc|
  doc.file_content_type if doc.is_a?(BrandAmbassadors::Document)
end

node :url do |doc|
  doc.download_url if doc.is_a?(BrandAmbassadors::Document)
end

node :thumbnail do |doc|
  doc.file.url(:small) if doc.is_a?(BrandAmbassadors::Document)
end