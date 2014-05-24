ActiveAdmin.register User do
  config.clear_action_items!

  actions :all, :except => [:new, :create]

  index do
    column :first_name
    column :last_name
    column :email
    column :current_sign_in_at
    column :last_sign_in_at
    column :sign_in_count
    default_actions
  end

  filter :email
  filter :first_name
  filter :last_name
  filter :company_users_company_id, :as => :select, :collection => proc { Company.all }
  filter :company_users_active_is_true, as: :boolean, default: true, label: 'Active'
  filter :active, as: :boolean, default: true, label: 'Invitation Accepted'

  form do |f|
    f.inputs "User Details" do
      f.input :first_name
      f.input :last_name
    end
    f.inputs "User Address" do
      f.input :country
      f.input :state
      f.input :city
      f.input :time_zone
      f.input :phone_number
      f.input :street_address
      f.input :unit_number
      f.input :zip_code
    end
    f.inputs "Authentication Info" do
      f.input :email
      f.input :password, required: false
      f.input :password_confirmation, required: false
    end
    f.actions
  end

  show do
    attributes_table do
      row :first_name
      row :last_name
      row :email
      row :country
      row :state
      row :city
      row :time_zone
      row :phone_number
      row :street_address
      row :unit_number
      row :zip_code
    end
  end

 csv do
    column :first_name
    column :last_name
    column("Role") { |user| user.company_users.joins(:role).pluck('roles.name').join(', ') }
    column :email
    column :country
    column :state
    column :city
    column :time_zone
    column :phone_number
    column :street_address
    column :unit_number
    column :zip_code
    column :current_sign_in_at
    column :last_sign_in_at
    column :sign_in_count
  end

  controller do
    def permitted_params
      params.permit(:user => [
        :email, :first_name, :last_name,
        :country, :state, :city, :time_zone, :phone_number, :street_address,
        :unit_number, :zip_code, :password, :password_confirmation])
    end
  end
end
