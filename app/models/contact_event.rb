class ContactEvent < ActiveRecord::Base
  belongs_to :contact
  belongs_to :event

  accepts_nested_attributes_for :contact

  delegate :full_name, :street1, :street2, :city, :company_id, :country, :email, :first_name, :last_name, :phone_number, :state, :title, :zip_code, to: :contact
end
