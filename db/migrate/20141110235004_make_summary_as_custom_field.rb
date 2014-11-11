class MakeSummaryAsCustomField < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do
      Campaign.all.each do |campaign|
        field = FormField::TextArea.create(fieldable: campaign, name: 'Summary', required: false, ordering: 0)
        campaign.events.find_each do |event|
          next if event.summary.blank?
          result = event.results_for([field]).first
          result.value = event.summary
          result.save
        end
      end
    end

    remove_column :events, :summary
  end
end
