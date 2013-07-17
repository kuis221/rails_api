class AddCaptureMechanismToFormFields < ActiveRecord::Migration
  def change
    add_column :campaign_form_fields, :capture_mechanism, :string
  end
end
