require 'spec_helper'

describe Api::V1::UsersController, :type => :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }

  describe "GET 'index'", search: true do
    before do
      user.reload  # Make sure the user is created
      Sunspot.commit
    end
    it "should return failure for invalid authorization token" do
      get :index, company_id: company.id, auth_token: 'XXXXXXXXXXXXXXXX', format: :json
      expect(response.response_code).to eq(401)
      result = JSON.parse(response.body)
      expect(result['success']).to eq(false)
      expect(result['info']).to eq('Invalid auth token')
      expect(result['data']).to be_empty
    end

    it "returns an empty list of users" do
      get :index, company_id: company.id, auth_token: user.authentication_token, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result).to eq([{
        "id" => user.company_users.first.id,
        "first_name" => user.first_name,
        "last_name" => user.last_name,
        "full_name" => user.full_name,
        "role_name" => user.company_users.first.role.name,
        "email" => user.email,
        "phone_number" => user.phone_number,
        "street_address" => user.street_address,
        "unit_number"=>"Unit Number 456",
        "city" => user.city,
        "state" => user.state,
        "zip_code" => user.zip_code,
        "time_zone"=>"Pacific Time (US & Canada)",
        "country" => user.country_name}])
    end

    it "should filter the users by role" do
      role = FactoryGirl.create(:role, company: company)
      another_user = FactoryGirl.create(:company_user, company: company, role: role)
      Sunspot.commit
      get :index, company_id: company.id, auth_token: user.authentication_token, role: [role.id], format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result.count).to eq(1)
      expect(result.first).to include(
        "id" => another_user.id,
        "role_name" => role.name
      )
    end

    it "should return only active users" do
      role = user.company_users.first.role
      inactive_user = FactoryGirl.create(:company_user, user: FactoryGirl.create(:user), company: company, role: role, active: false)
      invited_user = FactoryGirl.create(:company_user, user: FactoryGirl.create(:invited_user), company: company, role: role)
      Sunspot.commit
      get :index, company_id: company.id, auth_token: user.authentication_token, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result.count).to eq(1)
      expect(result.first).to include(
        "id" => user.company_users.first.id,
        "role_name" => role.name
      )
    end
  end

  describe "GET 'show'" do
    let(:the_user){ FactoryGirl.create(:company_user, company_id: company.to_param) }
    it "should return the user's info" do
      get 'show', auth_token: user.authentication_token, company_id: company.to_param, id: the_user.to_param, format: :json
      expect(assigns(:user)).to eq(the_user)

      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result).to eq({
        "id" => the_user.id,
        "first_name" => the_user.first_name,
        "last_name" => the_user.last_name,
        "full_name" => the_user.full_name,
        "email" => the_user.email,
        "phone_number" => the_user.phone_number,
        "street_address" => the_user.street_address,
        "unit_number"=> the_user.unit_number,
        "city" => the_user.city,
        "state" => the_user.state,
        "zip_code" => the_user.zip_code,
        "time_zone"=> the_user.time_zone,
        "country" => the_user.country_name,
        "role" => {
            "id" => the_user.role.id,
            "name" => the_user.role.name
        },
        "teams" => []
      })
    end
  end

  describe "PUT 'update'" do
    let(:the_user){ FactoryGirl.create(:company_user, company_id: company.to_param) }
    it "should update the user profile attributes" do
      put 'update', auth_token: user.authentication_token, company_id: company.to_param, id: the_user.to_param, company_user: {user_attributes: {first_name: 'Updated Name', last_name: 'Updated Last Name'}}, format: :json
      expect(assigns(:user)).to eq(the_user)

      expect(response).to be_success
      the_user.reload
      expect(the_user.first_name).to eq('Updated Name')
      expect(the_user.last_name).to eq('Updated Last Name')
    end

    it "must update the user password" do
      old_password = the_user.user.encrypted_password
      put 'update', auth_token: user.authentication_token, company_id: company.to_param, id: the_user.to_param, company_user: {user_attributes: {password: 'Juanito123', password_confirmation: 'Juanito123'}}, format: :json
      expect(assigns(:user)).to eq(the_user)
      expect(response).to be_success
      the_user.reload
      expect(the_user.user.encrypted_password).not_to eq(old_password)
    end

    it "user have to enter the phone number, country, state, city, street address and zip code information when editing his profile" do
      put 'update', auth_token: user.authentication_token, company_id: company.to_param, id: the_user.to_param, company_user: {user_attributes: {first_name: 'Juanito', last_name: 'Perez', email: 'test@testing.com', phone_number: '', city: '', state: '', country: '', street_address: '', zip_code: '', password: 'Juanito123', password_confirmation: 'Juanito123'}}, format: :json
      result = JSON.parse(response.body)
      expect(result['user.phone_number']).to eq(["can't be blank"])
      expect(result['user.country']).to eq(["can't be blank"])
      expect(result['user.state']).to eq(["can't be blank"])
      expect(result['user.city']).to eq(["can't be blank"])
      expect(result['user.street_address']).to eq(["can't be blank"])
      expect(result['user.zip_code']).to eq(["can't be blank"])
    end
  end

  describe "POST 'new_password'" do
    it "should return failure for a non-existent user" do
      expect(Devise::Mailer).not_to receive(:reset_password_instructions)
      post 'new_password', email:"fake@email.com", format: :json
      expect(response.response_code).to eq(401)
      result = JSON.parse(response.body)
      expect(result['success']).to eq(false)
      expect(result['info']).to eq('Action Failed')
      expect(result['data']).to be_empty
    end

    it "should return failure for an inactive user" do
      expect(Devise::Mailer).not_to receive(:reset_password_instructions)
      inactive_user = FactoryGirl.create(:company_user, company: FactoryGirl.create(:company), user: FactoryGirl.create(:user), active: false)
      post 'new_password', email: inactive_user.email, format: :json
      expect(response.response_code).to eq(401)
      result = JSON.parse(response.body)
      expect(result['success']).to eq(false)
      expect(result['info']).to eq('Action Failed')
      expect(result['data']).to be_empty
    end

    it "should return failure for an active user with inactive role" do
      expect(Devise::Mailer).not_to receive(:reset_password_instructions)
      company = FactoryGirl.create(:company)
      inactive_user = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user), role: FactoryGirl.create(:role, company: company, active: false))
      post 'new_password', email: inactive_user.email, format: :json
      expect(response.response_code).to eq(401)
      result = JSON.parse(response.body)
      expect(result['success']).to eq(false)
      expect(result['info']).to eq('Action Failed')
      expect(result['data']).to be_empty
    end

    it "should send reset password instructions to the user" do
      expect(Devise::Mailer).to receive(:reset_password_instructions).and_return(double(deliver: true))
      post 'new_password', email: user.email, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result['success']).to eq(true)
      expect(result['info']).to eq('Reset password instructions sent')
      expect(result['data']).to be_empty

      user.reload
      expect(user.reset_password_token).not_to be_nil
    end
  end

  describe "GET 'companies'" do
    it "should return failure for invalid authorization token" do
      get 'companies', auth_token: 'XXXXXXXXXXXXXXXX', format: :json
      expect(response.response_code).to eq(401)
      result = JSON.parse(response.body)
      expect(result['success']).to eq(false)
      expect(result['info']).to eq('Invalid auth token')
      expect(result['data']).to be_empty
    end

    it "should return list of companies associated to the current logged in user" do
      company = user.company_users.first.company
      company2 = FactoryGirl.create(:company)
      FactoryGirl.create(:company_user, company: company2, user: user, role: FactoryGirl.create(:role, company: company2))
      get 'companies', auth_token: user.authentication_token, format: :json
      companies = JSON.parse(response.body)
      expect(companies).to match_array([
        {'name' => company.name,  'id' => company.id },
        {'name' => company2.name, 'id' => company2.id}
      ])
      expect(response).to be_success
    end
  end

  describe "GET 'notifications'" do
    let(:company) { user.company_users.first.company }
    it "should return failure for invalid authorization token" do
      get 'notifications', auth_token: 'XXXXXXXXXXXXXXXX',company_id: company.id, format: :json
      expect(response.response_code).to eq(401)
      result = JSON.parse(response.body)
      expect(result['success']).to eq(false)
      expect(result['info']).to eq('Invalid auth token')
      expect(result['data']).to be_empty
    end
    it "should return empty list if the user has no notifications" do
      get 'notifications', auth_token: user.authentication_token, company_id: company.id, format: :json

      expect(response).to be_success
      notifications = JSON.parse(response.body)
      expect(notifications).to match_array([])
    end
  end

  describe "GET 'permissions'" do
    let(:company) { user.company_users.first.company }
    it "should return failure for invalid authorization token" do
      get 'permissions', auth_token: 'XXXXXXXXXXXXXXXX',company_id: company.id, format: :json
      expect(response.response_code).to eq(401)
      result = JSON.parse(response.body)
      expect(result['success']).to eq(false)
      expect(result['info']).to eq('Invalid auth token')
      expect(result['data']).to be_empty
    end

    it "should require the company_id param" do
      company = FactoryGirl.create(:company)
      FactoryGirl.create(:company_user, company: company, user: user, role: FactoryGirl.create(:role, company: company))
      expect{
        get 'permissions', auth_token: user.authentication_token, format: :json
      }.to raise_exception(Apipie::ParamMissing, 'Missing parameter company_id')
    end

    it "should return list of permissions for the current user" do
      company = FactoryGirl.create(:company)
      FactoryGirl.create(:company_user, company: company, user: user, role: FactoryGirl.create(:role, company: company))
      get 'permissions', auth_token: user.authentication_token, company_id: company.id, format: :json
      expect(response).to be_success
      permissions = JSON.parse(response.body)
      expect(permissions).to match_array(["events", "events_add_contacts", "events_add_team_members", "events_contacts", "events_create", "events_create_documents",
        "events_create_expenses", "events_create_photos", "events_create_surveys", "events_create_tasks", "events_deactivate_documents", "events_deactivate_expenses",
        "events_deactivate_photos", "events_deactivate_surveys", "events_delete_contacts", "events_delete_team_members", "events_documents", "events_edit_contacts",
        "events_edit_expenses", "events_edit_surveys", "events_edit_tasks", "events_expenses", "events_deactivate", "events_edit", "events_photos", "events_show", "events_surveys", "events_tasks",
        "events_team_members", "events_comments", "events_create_comments", "events_deactivate_comments", "events_edit_comments", "tasks_comments_own", "tasks_comments_team",
        "tasks_create_comments_own", "tasks_create_comments_team", "tasks_deactivate_own", "tasks_deactivate_team", "tasks_edit_own", "tasks_edit_team", "tasks_own", "tasks_team", "venues", "venues_create",
        "venues_comments", "venues_kpis", "venues_photos", "venues_score", "venues_show", "venues_trends"])
    end

    it "should return empty list if the user has no permissions" do
      role = FactoryGirl.create(:non_admin_role, company: company)
      non_admin = FactoryGirl.create(:user, company_users: [FactoryGirl.create(:company_user, company: company, role: role)])

      get 'permissions', auth_token: non_admin.authentication_token, company_id: company.id, format: :json

      expect(response).to be_success
      permissions = JSON.parse(response.body)
      expect(permissions).to match_array([])
    end

    it "should return only the permissions given to the user's role" do
      role = FactoryGirl.create(:non_admin_role, company: company,)
      non_admin = FactoryGirl.create(:user, company_users: [FactoryGirl.create(:company_user, company: company, role: role)])

      role.permissions.create(action: :create, subject_class: 'Event')
      role.permissions.create(action: :view_list, subject_class: 'Event')

      get 'permissions', auth_token: non_admin.authentication_token, company_id: company.id, format: :json

      expect(response).to be_success
      permissions = JSON.parse(response.body)
      expect(permissions).to match_array(["events", "events_create"])
    end
  end
end