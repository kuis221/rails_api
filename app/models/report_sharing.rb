# == Schema Information
#
# Table name: report_sharings
#
#  id               :integer          not null, primary key
#  report_id        :integer
#  shared_with_id   :integer
#  shared_with_type :string(255)
#

class ReportSharing < ActiveRecord::Base
  belongs_to :report

  belongs_to :shared_with, polymorphic: true
end
