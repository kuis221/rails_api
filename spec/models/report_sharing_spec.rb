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

describe ReportSharing do
  pending "add some examples to (or delete) #{__FILE__}"
end
