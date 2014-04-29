class AddReportSharingFieldsAndTables < ActiveRecord::Migration
  def change
  	unless ActiveRecord::Base.connection.table_exists? 'report_sharings'
      create_table :report_sharings do |t|
        t.references :report
        t.integer :shared_with_id
        t.string :shared_with_type
      end
      add_index :report_sharings, [:shared_with_id, :shared_with_type]

      add_column :reports, :sharing, :string, default: 'owner'
    end
  end
end
