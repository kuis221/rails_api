class CreateCampaignFormFields < ActiveRecord::Migration
  def change
    create_table :campaign_form_fields do |t|
      t.references :campaign
      t.references :kpi
      t.integer :ordering
      t.string :name
      t.string :type
      t.text :options
      t.integer :section_id

      t.timestamps
    end
    add_index :campaign_form_fields, :campaign_id
    add_index :campaign_form_fields, :kpi_id
  end
end
