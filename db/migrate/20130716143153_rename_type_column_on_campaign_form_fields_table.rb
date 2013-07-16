class RenameTypeColumnOnCampaignFormFieldsTable < ActiveRecord::Migration
  def change
    rename_column :campaign_form_fields, :type, :field_type
  end
end
