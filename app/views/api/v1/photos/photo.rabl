attributes :id, :file_file_name, :file_content_type, :file_file_size, :created_at, :active

node :file_small do |r|
  r.processed? ? r.file.url(:small) : nil
end

node :file_thumbnail do |r|
  r.processed? ? r.file.url(:thumbnail) : nil
end

node :file_medium do |r|
  r.processed? ? r.file.url(:medium) : nil
end

node :file_original do |r|
  r.processed? ? r.file.url : nil
end