class Api::V1::ContactsController < Api::V1::ApiController

  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  resource_description do
    short 'Contacts'
    formats ['json', 'xml']
    error 404, "Missing"
    error 500, "Server crashed for some reason"
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
    * *street_address*: the user's street name and number
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
            "street_address": "1st Young st.,",
            "city": "Toronto",
            "state": "ON",
            "country": "Canada",
            "zip_code": "Canada"
        }
    ]
  EOS

  def index
    @contacts = current_company.contacts
  end

end