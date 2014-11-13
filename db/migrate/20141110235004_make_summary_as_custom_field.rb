class MakeSummaryAsCustomField < ActiveRecord::Migration
  def change
    Campaign.all.each do |campaign|
      campaign.form_fields.update_all('ordering = ordering + 1')
      field = FormField::TextArea.create(fieldable: campaign, name: 'Summary', required: false, ordering: 0)
      execute 'INSERT INTO form_field_results'\
              '(form_field_id, value, resultable_id, resultable_type, created_at, updated_at) ('\
              "  SELECT #{field.id}, events.summary, events.id, 'Event', events.updated_at, events.updated_at"\
              '   FROM events '\
              "  WHERE campaign_id=#{campaign.id} and events.summary IS NOT NULL and events.summary <> '')"
    end

    remove_column :events, :summary
  end
end
