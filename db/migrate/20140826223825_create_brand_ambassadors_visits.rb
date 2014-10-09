class CreateBrandAmbassadorsVisits < ActiveRecord::Migration
  def change
    create_table :brand_ambassadors_visits do |t|
      t.string :name
      t.references :company, index: true
      t.references :company_user, index: true
      t.date :start_date
      t.date :end_date
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
