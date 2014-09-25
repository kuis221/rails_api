class ConvertCampaignFormFields < ActiveRecord::Migration
  HASHED_FIELD_TYPES = [
    'FormField::Checkbox', 'FormField::Percentage']
  def up
    rename_table :activity_results, :form_field_results
    add_column :campaigns, :enabled_modules, :string, array: true, default: []
    add_column :form_fields, :kpi_id, :integer
    change_table :form_field_results do |t|
      t.references :resultable, polymorphic: true
    end
    execute("UPDATE form_field_results set resultable_id=activity_id, resultable_type='Activity'")
    remove_column :form_field_results, :activity_id

    Campaign.reset_column_information
    Campaign.find_each do |campaign|
      enabled_modules = []
      CampaignFormField.where(campaign_id: campaign.id).find_each do |cff|
        if type = cff.migration_type
          field = type.constantize.create(
            fieldable: campaign,
            kpi_id: cff.kpi_id,
            name: cff.name,
            ordering: cff.ordering,
            required: cff.is_required?
          )

          # Migrate all results to the form_field_results table
          if type == 'FormField::Percentage'
            execute "INSERT INTO form_field_results
              (resultable_id, resultable_type, form_field_id,  value, scalar_value, hash_value, created_at, updated_at)
              (SELECT event_id, \'Event\', #{field.id}, NULL, 0, '', now(), now()
               FROM event_results WHERE form_field_id=#{cff.id} AND kpis_segment_id is not null
               GROUP by event_id, form_field_id)"

            cff.kpi.kpis_segments.each do |segment|
              execute "UPDATE form_field_results fr SET hash_value = hash_value || hstore('#{segment.id}', er.value)
                       FROM event_results AS er
                       WHERE er.event_id=fr.resultable_id AND fr.resultable_type='Event' AND
                             er.kpis_segment_id=#{segment.id} AND
                             er.form_field_id=#{cff.id} AND fr.form_field_id=#{field.id}"
            end
          else
            execute "INSERT INTO form_field_results
              (resultable_id, resultable_type, form_field_id, value, scalar_value, created_at, updated_at)
              (SELECT event_id, \'Event\', #{field.id}, value, scalar_value, created_at, updated_at
               FROM event_results WHERE form_field_id=#{cff.id} AND kpis_segment_id is null)"
          end
        elsif %w(videos expenses comments photos surveys).include?(cff.field_type)
          enabled_modules.push cff.field_type
        else
          fail "Unnknow field_type #{cff.field_type}"
        end
      end
      campaign.update_column :enabled_modules, enabled_modules if enabled_modules.any?
    end

    drop_table :campaign_form_fields
  end

  def down
  end
end
