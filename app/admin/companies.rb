ActiveAdmin.register Company do
  actions :index, :show, :edit, :update, :new, :create

  filter :name

  form do |f|
    f.inputs "Details" do
      f.input :name
      f.input :admin_email if f.object.new_record?
    end
    f.inputs "Date/Time Settings" do
      f.input :timezone_support
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit(:company => [:name, :admin_email, :timezone_support])
    end
  end
end