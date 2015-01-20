collection @invites


attributes :id, :invitees, :rsvps_count, :attendees, :active

child(:event) do
  attributes :id, :start_date, :end_date
end

child(:venue) do
  attributes :id, :name, :top_venue, :jameson_locals
end