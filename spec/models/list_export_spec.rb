# == Schema Information
#
# Table name: list_exports
#
#  id                :integer          not null, primary key
#  params            :text
#  export_format     :string(255)
#  aasm_state        :string(255)
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  company_user_id   :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  controller        :string(255)
#  progress          :integer          default(0)
#

require 'spec_helper'

describe ListExport do
  let(:company_user) { FactoryGirl.create(:company_user) }


  describe "Results::EventDataController#export_list" do
    it "should call the export_list on the controller and set the required variables" do
      exporter = ListExport.new(controller: 'Results::EventDataController', company_user: company_user, export_format: 'xls', params: {})
      Results::EventDataController.any_instance.should_receive(:export_list).with(exporter)

      # Prevent export to save and upload attachment to S3
      exporter.should_receive(:save).any_number_of_times.and_return(true)

      exporter.file_file_name.should be_nil
      exporter.export_list

      exporter.file_file_name.should_not be_nil
      User.current.should == company_user.user
      exporter.completed?.should be_true
    end
  end

  describe "EventsController#export_list" do
    it "should call the export_list on the controller and set the required variables" do
      exporter = ListExport.new(controller: 'EventsController', company_user: company_user, export_format: 'xls', params: {})
      EventsController.any_instance.should_receive(:export_list).with(exporter)

      # Prevent export to save and upload attachment to S3
      exporter.should_receive(:save).any_number_of_times.and_return(true)

      exporter.file_file_name.should be_nil
      exporter.export_list

      exporter.file_file_name.should_not be_nil
      User.current.should == company_user.user
      exporter.completed?.should be_true
    end
  end
end
