ActiveAdmin.register Event do
  actions :index, :show

  sidebar :versionate, partial: 'admin/shared/version', only: :show

  index do
    column :id
    column :company_name do |event|
      event.company.try(:name)
    end
    column :campaing_name do |event|
      event.campaign.try(:name)
    end
    column :start_at
    column :end_at
    column :place_name
    actions
  end

  controller do
    def scoped_collection
      end_of_association_chain.eager_load(:company, :campaign, :place)
    end
  end

  filter :id
  filter :company
  filter :campaign
  filter :start_at
  filter :end_at
  filter :created_at
  filter :updated_at
end
