# == Schema Information
#
# Table name: invite_individuals
#
#  id                               :integer          not null, primary key
#  invite_id                        :integer
#  registrant_id                    :integer
#  date_added                       :date
#  email                            :string(255)
#  mobile_phone                     :string(255)
#  mobile_signup                    :boolean
#  first_name                       :string(255)
#  last_name                        :string(255)
#  attended_previous_bartender_ball :string(255)
#  opt_in_to_future_communication   :boolean
#  primary_registrant_id            :integer
#  bartender_how_long               :string(255)
#  bartender_role                   :string(255)
#  created_at                       :datetime
#  updated_at                       :datetime
#  date_of_birth                    :string(255)
#  zip_code                         :string(255)
#  created_by_id                    :integer
#  updated_by_id                    :integer
#  attended                         :boolean
#

require 'rails_helper'

RSpec.describe InviteIndividual, type: :model do
  let(:event) { create :event }
  describe 'callbacks' do
    describe 'after_create' do
      it "must increment invite's counters" do
        invite = create :invite, event: event, invitees: 0, rsvps_count: 0, attendees: 0
        create :invite_individual, invite: invite, attended: true, rsvpd: true
        expect(invite.reload.invitees).to eql 1
        expect(invite.attendees).to eql 1
        expect(invite.rsvps_count).to eql 1

        create :invite_individual, invite: invite, attended: false, rsvpd: true
        expect(invite.reload.invitees).to eql 2
        expect(invite.attendees).to eql 1
        expect(invite.rsvps_count).to eql 2

        create :invite_individual, invite: invite, attended: false, rsvpd: false
        expect(invite.reload.invitees).to eql 3
        expect(invite.attendees).to eql 1
        expect(invite.rsvps_count).to eql 2
      end
    end

    describe 'after_update' do
      it "must update invite's counters" do
        invite = create :invite, event: event, invitees: 10, rsvps_count: 10, attendees: 10
        individual = create :invite_individual, invite: invite, attended: true, rsvpd: true
        expect(invite.reload.invitees).to eql 11
        expect(invite.attendees).to eql 11
        expect(invite.rsvps_count).to eql 11

        individual.update_attributes attended: false, rsvpd: true
        expect(invite.reload.invitees).to eql 11
        expect(invite.attendees).to eql 10
        expect(invite.rsvps_count).to eql 11

        individual.update_attributes rsvpd: false
        expect(invite.reload.invitees).to eql 11
        expect(invite.attendees).to eql 10
        expect(invite.rsvps_count).to eql 10
      end
    end

    describe 'on deactivate' do
      it 'updates the invite counters' do
        invite = create :invite, event: event, invitees: 10, rsvps_count: 10, attendees: 10
        individual = create :invite_individual, invite: invite, attended: true, rsvpd: true
        expect(invite.reload.invitees).to eql 11
        expect(invite.attendees).to eql 11
        expect(invite.rsvps_count).to eql 11

        individual.deactivate!

        expect(invite.reload.invitees).to eql 10
        expect(invite.attendees).to eql 10
        expect(invite.rsvps_count).to eql 10
      end
    end
  end
end
