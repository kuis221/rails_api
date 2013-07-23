class RemoveCaptureMechanismFromFormFieldsTable < ActiveRecord::Migration
  def up
    remove_column :campaign_form_fields, :capture_mechanism
  end

  def down
    add_column :campaign_form_fields, :capture_mechanism, :string
  end
end
