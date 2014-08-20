class Api::V1::ContactsController < Api::V1::ApiController
  inherit_resources

  skip_before_action :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  def_param_group :contact do
    param :contact, Hash, required: true, :action_aware => true do
      param :first_name, String, required: true, desc: "Contact's first name"
      param :last_name, String, required: true, desc: "Contact's last name"
      param :title, String, required: false, desc: "Contact's title"
      param :email, String, required: false, desc: "Contact's email address"
      param :phone_number, String, required: false, desc: "Contact's phone number'"
      param :street1, String, required: false, desc: "Contact's street address 1"
      param :street2, String, required: false, desc: "Contact's street address 2"
      param :country, String, desc: "Contact's country code, eg: US, UK, AR"
      param :state, String, required: false, desc: "Contact's state code, eg: CA, TX"
      param :city, String, required: false, desc: "Contact's city"
      param :zip_code, String, required: false, desc: "Contact's ZIP code"
    end
  end

  resource_description do
    short 'Contacts'
    formats ['json', 'xml']
    error 406, "The server cannot return data in the requested format"
    error 404, "The requested resource was not found"
    error 500, "Server crashed for some reason. Possible because of missing required params or wrong parameters"
    param :auth_token, String, required: true, desc: "User's authorization token returned by login method"
    param :company_id, :number, required: true, desc: "One of the allowed company ids returned by the \"User companies\" API method"
    description <<-EOS

    EOS
  end

  api :GET, '/api/v1/contacts', "Get a list of contacts for a specific company"
  description <<-EOS
    Returns a full list of the existing users in the company
    Each user have the following attributes:
    * *id*: the user id
    * *first_name*: the user's first name
    * *last_name*: the user's last name
    * *full_name*: the user's full name
    * *email*: the user's email address
    * *street1*: the user's street address (Line 1)
    * *street2*: the user's street address (Line 2)
    * *street_address*: the user's street name and number, this is the concatanation of stree1+street2
    * *city*: the user's city name
    * *state*: the user's state code
    * *country*: the user's country
    * *zip_code*: the user's ZIP code
    * *title*: the user's role name
  EOS
  example <<-EOS
    A list of contacts for company id 1:
    GET /api/v1/contacts?auth_token=XXXXXYYYYYZZZZZ&company_id=1
    [
        {
            "id": 268,
            "first_name": "Trinity",
            "last_name": "Ruiz",
            "full_name": "Trinity Ruiz",
            "title": "MBN Supervisor",
            "email": "trinity.ruiz@gmail.com",
            "phone_number": "+1 233 245 4332",
            "street1": "1st Young st.,",
            "street2": "4th floor, Aptm, #3,",
            "street_address": "1st Young st., 4th floor, Aptm, #3",
            "city": "Toronto",
            "state": "ON",
            "country": "CA",
            "country_name": "Canada",
            "zip_code": "12345"
        }
    ]
  EOS
  def index
    @contacts = current_company.contacts.order('contacts.first_name, contacts.last_name')
  end


  api :GET, '/api/v1/contacts/:id', 'Return a contact\'s details'
  param :id, :number, required: true, desc: "Contact ID"

  example <<-EOS
  {
      "id": 268,
      "first_name": "Trinity",
      "last_name": "Blue",
      "full_name": "Trinity Blue",
      "title": "MBN Supervisor",
      "email": "trinity@matrix.com",
      "phone_number": "+1 233 245 4332",
      "stree1": "1st Young st.,",
      "stree2": "2nd floor, #34",
      "street_address": "1st Young st., 2nd floor, #34"",
      "city": "Toronto",
      "state": "ON",
      "country": "CA",
      "country_name": "Canada",
      "zip_code": "12345"
  }
  EOS
  def show
    if resource.present?
      render
    end
  end

  api :POST, '/api/v1/contacts', 'Create a new contact'
  error 422, "There is one or more invalid attributes for the contact"
  param_group :contact
  description <<-EOS
  Creates a new contact and returns all the contact's info, including the assigned unique ID.
  EOS
  example <<-EOS
    POST /api/v1/contacts?auth_token=XXXXXYYYYYZZZZZ&company_id=1
    DATA:
    {
        contact: {
            "first_name": "Trinity",
            "last_name": "Blue",
            "full_name": "Trinity Blue",
            "title": "MBN Supervisor",
            "email": "trinity@matrix.com",
            "phone_number": "+1 233 245 4332",
            "stree1": "1st Young st.,",
            "stree2": "2nd floor, #34",
            "city": "Toronto",
            "state": "ON",
            "country": "CA",
            "zip_code": "12345"
        }
    }

    RESPONSE:
    {
        "id": 268,
        "first_name": "Trinity",
        "last_name": "Blue",
        "full_name": "Trinity Blue",
        "title": "MBN Supervisor",
        "email": "trinity@matrix.com",
        "phone_number": "+1 233 245 4332",
        "stree1": "1st Young st.,",
        "stree2": "2nd floor, #34",
        "street_address": "1st Young st., 2nd floor, #34"",
        "city": "Toronto",
        "state": "ON",
        "country": "Canada",
        "zip_code": "12345"
    }
  EOS
  def create
    create! do |success, failure|
      success.json { render :show }
      success.xml { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  api :PUT, '/api/v1/contacts/:id', 'Update a contact\'s details'
  param :id, :number, required: true, desc: "Contact ID"
  param_group :contact
  description <<-EOS
  Updates a contact's information and returns all the contact's updated info.
  EOS
  example <<-EOS
    PUT /api/v1/contacts/268?auth_token=XXXXXYYYYYZZZZZ&company_id=1
    DATA:
    {
        contact: {
            "first_name": "Trinity",
            "last_name": "Blue",
            "full_name": "Trinity Blue",
            "title": "MBN Supervisor",
            "email": "trinity@matrix.com",
            "phone_number": "+1 233 245 4332",
            "stree1": "1st Young st.,",
            "stree2": "2nd floor, #34",
            "city": "Toronto",
            "state": "ON",
            "country": "CA",
            "zip_code": "12345"
        }
    }

    RESPONSE:
    {
        "id": 268,
        "first_name": "Trinity",
        "last_name": "Blue",
        "full_name": "Trinity Blue",
        "title": "MBN Supervisor",
        "email": "trinity@matrix.com",
        "phone_number": "+1 233 245 4332",
        "stree1": "1st Young st.,",
        "stree2": "2nd floor, #34",
        "street_address": "1st Young st., 2nd floor, #34"",
        "city": "Toronto",
        "state": "ON",
        "country": "CA",
        "country_name": "Canada",
        "zip_code": "12345"
    }
  EOS
  def update
    update! do |success, failure|
      success.json { render :show }
      success.xml  { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml  { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  protected
    def build_resource_params
      [params.require(:contact).permit(:first_name, :last_name, :title, :email, :phone_number, :street1, :street2, :city, :state, :country, :zip_code)]
    end
end