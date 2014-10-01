module BrandscopiSpecHelpers
  def sign_in_as_user(company_user = nil)
    if company_user.present?
      company = company_user.company
      user = company_user.user
    else
      company = create(:company_with_user)
      user = company.company_users.first.user
    end
    User.current = user
    user.current_company = company
    user.ensure_authentication_token
    user.update_attributes(attributes_for(:user).reject { |k, _v| %w(password password_confirmation email).include?(k.to_s) })
    sign_in user
    user
  end

  def set_event_results(event, results, autosave = true)
    event.result_for_kpi(Kpi.impressions).value = results[:impressions] if results.key?(:impressions)
    event.result_for_kpi(Kpi.interactions).value = results[:interactions] if results.key?(:interactions)
    event.result_for_kpi(Kpi.samples).value = results[:samples] if results.key?(:samples)
    result = event.result_for_kpi(Kpi.gender)
    segments = Kpi.gender.kpis_segments
    value = {}
    value[segments.find { |s| s.text == 'Male' }.id]  = results[:gender_male] if results.key?(:gender_male)
    value[segments.find { |s| s.text == 'Female' }.id] = results[:gender_female] if results.key?(:gender_female)
    result.value = value

    result = event.result_for_kpi(Kpi.ethnicity)
    segments = Kpi.ethnicity.kpis_segments
    value = {}
    value[segments.find { |s| s.text == 'Asian' }.id] = results[:ethnicity_asian] if results.key?(:ethnicity_asian)
    value[segments.find { |s| s.text == 'Native American' }.id] = results[:ethnicity_native_american] if results.key?(:ethnicity_native_american)
    value[segments.find { |s| s.text == 'Black / African American' }.id] = results[:ethnicity_black] if results.key?(:ethnicity_black)
    value[segments.find { |s| s.text == 'Hispanic / Latino' }.id] = results[:ethnicity_hispanic] if results.key?(:ethnicity_hispanic)
    value[segments.find { |s| s.text == 'White' }.id] = results[:ethnicity_white] if results.key?(:ethnicity_white)
    result.value = value

    result = event.result_for_kpi(Kpi.age)
    segments = Kpi.age.kpis_segments
    value = {}
    value[segments.find { |s| s.text == '< 12' }.id] = results[:age_12] if results.key?(:age_12)
    value[segments.find { |s| s.text == '12 – 17' }.id] = results[:age_12_17] if results.key?(:age_12_17)
    value[segments.find { |s| s.text == '18 – 24' }.id] = results[:age_18_24] if results.key?(:age_18_24)
    value[segments.find { |s| s.text == '25 – 34' }.id] = results[:age_25_34] if results.key?(:age_25_34)
    value[segments.find { |s| s.text == '35 – 44' }.id] = results[:age_35_44] if results.key?(:age_35_44)
    value[segments.find { |s| s.text == '45 – 54' }.id] = results[:age_45_54] if results.key?(:age_45_54)
    value[segments.find { |s| s.text == '55 – 64' }.id] = results[:age_55_64] if results.key?(:age_55_64)
    value[segments.find { |s| s.text == '65+' }.id] = results[:age_65] if results.key?(:age_65)
    result.value = value

    event.save if autosave
  end

  def without_current_user
    user = User.current
    User.current = nil
    yield
  ensure
    User.current = user
  end

  def spreadsheet_from_last_export
    require 'rexml/document'
    export = ListExport.last
    expect(export).to receive(:save).at_least(:once).and_return(true)
    export.export_list
    yield REXML::Document.new(export.file.instance_variable_get(:@file).read)
  end
end

RSpec.configure do |config|
  config.include BrandscopiSpecHelpers
end
