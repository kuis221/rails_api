class MakeSummaryAsCustomField < ActiveRecord::Migration
  def change
    Campaign.all.each do |campaign|
      campaign.form_fields.update_all('ordering = ordering + 1')
      field = FormField::TextArea.create(fieldable: campaign, name: 'Summary', required: false, ordering: 0)
      campaign.events.where.not(summary: nil).where.not(summary: '').find_each do |event|
        result = event.results_for([field]).first
        result.value = event.summary
        result.save
      end
    end

    remove_column :events, :summary
  end
end
