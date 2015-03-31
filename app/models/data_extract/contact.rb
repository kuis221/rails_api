# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  filters          :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#

class DataExtract::Contact < DataExtract
  define_columns first_name: 'first_name',
                 last_name: 'last_name',
                 title: 'title',
                 email: 'email',
                 phone_number: 'phone_number',
                 street1: 'street1',
                 street2: 'street2',
                 country: 'country',
                 state: 'state',
                 city: 'city',
                 zip_code: 'zip_code',
                 created_at: proc { "to_char(contacts.created_at, 'MM/DD/YYYY')" }

  def total_results
    Contact.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end
end
