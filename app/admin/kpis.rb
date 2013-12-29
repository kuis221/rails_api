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
        redirect_to collection_path, :alert => 'Cannot merge different kind of KPIs'
      elsif @kpis.select{|k| k.out_of_the_box? }.count > 1
        redirect_to collection_path, :alert => 'It\'s not possible to merge two Out-of-the-box KPIs'
      elsif @kpis.map(&:company_id).compact.uniq.count > 1
        redirect_to collection_path, :alert => 'Cannot merge KPIs of different companies'
      elsif params[:merge].present? && params[:merge][:confirm] == 'Merge'
        if @campaigns.any? && @campaigns.count !=  params[:merge][:master_kpi].try(:count)
          flash[:error] = 'Please make sure to select a KPI for all the campaigns'
        else
          Resque.enqueue KpiMergeWorker, @kpis.map(&:id), params[:merge]

          redirect_to collection_path, :notice => 'A job have been queued to merge the KPIs. This can take up to 2 minutes depending of the number of events/campaigns those KPIs are used'
        end
      end
    end
  end

  collection_action :export_duplicated_data, :method => :get do
    kpis = Kpi.find(params[:kpis])
    file = CSV.generate do |csv|
      csv << ['Event'] + kpis.map(&:name)
      Campaign.find(params[:campaign_id]).events.find_in_batches do |group|
        group.each do |event|
          results = kpis.map{|k| event.result_for_kpi(k).try(:value)}.compact.uniq
          csv << [event_url(event)] + results if results.count > 1
        end
      end
    end
    respond_to do |format|
      format.csv { render text: file }
    end
  end

  controller do
    def apply_pagination(chain)
        chain = super unless formats.include?(:json) || formats.include?(:csv)
        chain
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