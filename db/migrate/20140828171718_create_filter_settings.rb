class CreateFilterSettings < ActiveRecord::Migration
  def change
    create_table :filter_settings do |t|
      t.references :company_user, index: true
      t.string :apply_to
      t.text :settings

      t.timestamps
    end
  end
end
