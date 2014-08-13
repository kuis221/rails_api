# == Schema Information
#
# Table name: report_sharings
#
#  id               :integer          not null, primary key
#  report_id        :integer
#  shared_with_id   :integer
#  shared_with_type :string(255)
#

require 'spec_helper'

describe ReportSharing, :type => :model do
  it { is_expected.to belong_to(:report) }
  it { is_expected.to belong_to(:shared_with) }
end
