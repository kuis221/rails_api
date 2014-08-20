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

require 'rails_helper'

describe ListExport, :type => :model do
  let(:company_user) { FactoryGirl.create(:company_user) }


  describe "Results::EventDataController#export_list" do
    it "should call the export_list on the controller and set the required variables" do
      exporter = ListExport.new(controller: 'Results::EventDataController', company_user: company_user, export_format: 'xls', params: {})
      expect_any_instance_of(Results::EventDataController).to receive(:export_list).with(exporter)

      # Prevent export to save and upload attachment to S3
      expect(exporter).to receive(:save).at_least(:once).and_return(true)

      expect(exporter.file_file_name).to be_nil
      exporter.export_list

      expect(exporter.file_file_name).not_to be_nil
      expect(User.current).to eq(company_user.user)
      expect(exporter.completed?).to be_truthy
    end
  end

  describe "EventsController#export_list" do
    it "should call the export_list on the controller and set the required variables" do
      exporter = ListExport.new(controller: 'EventsController', company_user: company_user, export_format: 'xls', params: {})
      expect_any_instance_of(EventsController).to receive(:export_list).with(exporter)

      # Prevent export to save and upload attachment to S3
      expect(exporter).to receive(:save).at_least(:once).and_return(true)

      expect(exporter.file_file_name).to be_nil
      exporter.export_list

      expect(exporter.file_file_name).not_to be_nil
      expect(User.current).to eq(company_user.user)
      expect(exporter.completed?).to be_truthy
    end
  end
end
