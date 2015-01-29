class CustomFiltersCategory < ActiveRecord::Base
  belongs_to :company
  scoped_to_company
end
