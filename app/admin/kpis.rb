ActiveAdmin.register Kpi do
  config.clear_action_items!
  actions :index, :show

  filter :name
  filter :description
  filter :kpi_type, :as => :select, :collection => proc { Kpi::CUSTOM_TYPE_OPTIONS.keys }

  batch_action :merge do |selection|
    if selection.count < 2
      redirect_to collection_path, :alert => 'Please select more than one KPI to merge'
    else
      kpis = Kpi.find(selection)
      if kpis.map(&:kpi_type).uniq.count > 2
        redirect_to collection_path, :alert => 'Cannot merge different kind of KPIs'
      else
        keep_kpi = kpis.shift
        Kpi.transaction do
          delete_kpi_ids = kpis.map(&:id)
          fields_to_delete = CampaignFormField.where(kpi_id: delete_kpi_ids).all

        end
      end
    end
  end

  index do
    selectable_column
    column :name
    column :description
    column :kpi_type
    column :capture_mechanism
    column :company_id
    default_actions

  end
end
