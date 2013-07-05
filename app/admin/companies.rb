ActiveAdmin.register Company do
  form do |f|
    f.inputs "Details" do
      f.input :name
      f.input :admin_email
    end
    f.actions
  end
end