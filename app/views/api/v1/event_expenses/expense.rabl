attributes :id, :category, :amount, :expense_date, :brand_id, :reimbursable, :billable, :merchant, :description

node :expense_date do |r|
  r.expense_date.to_s(:slashes) if r.expense_date
end

child :receipt => 'receipt' do

  attributes :id, :file_file_name, :file_content_type, :file_file_size, :created_at, :active

  node :file_small do |r|
    r.file.url(:small)
  end

  node :file_medium do |r|
    r.file.url(:medium)
  end

  node :file_original do |r|
    r.file.url
  end
end