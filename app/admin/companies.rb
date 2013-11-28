ActiveAdmin.register Company do
  actions :index, :show, :edit, :update, :new, :create

  form do |f|
    f.inputs "Details" do
      f.input :name
      f.input :admin_email
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit(:company => [:name, :admin_email])
    end
  end
end