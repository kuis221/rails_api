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
      @kpis = Kpi.where(id: selection)
      campaign_ids = @kpis.map{|k| CampaignFormField.where(kpi_id: k).map(&:campaign_id) }.flatten
      @campaigns = Campaign.where(id: campaign_ids.uniq)
      @conflict_campaigns = campaign_ids.select{|e| campaign_ids.rindex(e) != campaign_ids.index(e) }.uniq
      if @kpis.map(&:kpi_type).uniq.count > 1
        redirect_to :back, :alert => 'Cannot merge different kind of KPIs'
      elsif @kpis.map(&:module).uniq != ['custom']
        redirect_to :back, :alert => 'Merging global KPIs is not allowed'
      elsif @kpis.map(&:company_id).uniq.count > 1
        redirect_to :back, :alert => 'Cannot merge KPIs of different companies'
      elsif params[:merge].present? && params[:merge][:confirm] == 'Merge'
        if @campaigns.any? && @campaigns.count !=  params[:merge][:master_kpi].try(:count)
          flash[:error] = 'Please make sure to select a KPI for all the campaigns'
        else
          @kpis.merge_fields(params[:merge])

          redirect_to collection_path, :notice => 'The campaigns have been sucessfully merged'
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
