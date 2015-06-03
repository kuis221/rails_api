module JbbFile
  class KahluaRsvpReport < JbbFile::RsvpReport
    COLUMNS = {
      campaign: 'Campaign',
      market: 'Market',
      final_date: 'FinalDate',
      event_date: 'EventDate',
      registrant_id: 'RegistrantID',
      date_added: 'DateAdded',
      email: 'Email',
      mobile_phone: 'MobilePhone',
      mobile_signup: 'MobileSignup',
      first_name: 'FirstName',
      last_name: 'LastName',
      account_name: 'AccountName',
      attended_previous_bartender_ball: 'AttendedPreviousBartenderBall',
      opt_in_to_future_communication: 'OptInToFutureCommunication',
      primary_registrant_id: 'PrimaryRegistrantId',
      bartender_how_long: 'BartenderHowLong',
      bartender_role: 'BartenderRole',
      date_of_birth: 'DOB',
      zip_code: 'Zip Code'
    }
    INVITE_COLUMNS = [:market, :final_date]

    RSVP_COLUMNS = COLUMNS.keys - INVITE_COLUMNS - [:account_name, :event_date, :campaign]

    VALID_COLUMNS = COLUMNS.values
  end
end
