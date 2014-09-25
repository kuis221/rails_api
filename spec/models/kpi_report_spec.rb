# == Schema Information
#
# Table name: kpi_reports
#
#  id                :integer          not null, primary key
#  company_user_id   :integer
#  params            :text
#  aasm_state        :string(255)
#  progress          :integer
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'rails_helper'

describe KpiReport, type: :model do
  it { is_expected.to belong_to(:company_user) }
end
