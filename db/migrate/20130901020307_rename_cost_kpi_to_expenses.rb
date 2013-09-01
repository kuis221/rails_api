class RenameCostKpiToExpenses < ActiveRecord::Migration
  def up
    rename_column :event_data, :cost, :spent
    if kpi = Kpi.global.where(name: 'Cost').first
      kpi.update_attributes({name: 'Expenses', kpi_type: 'expenses', description: 'Total expenses related to the event'}, without_protection: true)
      CampaignFormField.where(kpi_id: kpi).update_all(name: 'Expenses', field_type: 'expenses')
    end
  end

  def down
    rename_column :event_data, :spent, :cost
  end
end
