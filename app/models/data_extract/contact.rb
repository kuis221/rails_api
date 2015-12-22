# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean          default("true")
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#  params           :text
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
                 created_at: proc { "to_char(contacts.created_at, 'MM/DD/YYYY')" },
                 created_by: '(SELECT trim(us.first_name || \' \' || us.last_name) FROM users as us WHERE contacts.created_by_id=us.id)',
                 modified_at: proc { "to_char(contacts.updated_at, 'MM/DD/YYYY')" },
                 modified_by: '(SELECT trim(us.first_name || \' \' || us.last_name) FROM users as us WHERE contacts.updated_by_id=us.id)'

  def add_joins_to_scope(s)
    if columns.include?('created_by') || filters.present? && filters['user'].present?
      s = s.joins('LEFT JOIN users ON contacts.created_by_id=users.id')
    end
    s
  end

  def total_results
    Contact.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end

  def sort_by_column(col)
    case col
    when 'created_at'
      'contacts.created_at'
    else
      super
    end
  end
end
