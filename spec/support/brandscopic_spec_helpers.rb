module BrandscopiSpecHelpers
  def sign_in_as_user
    company = FactoryGirl.create(:company_with_user)
    #role = FactoryGirl.create(:role, company: company, active: true, name: "Current User Role")
    role = company.roles.first
    User.current = user = company.company_users.first.user
    user.current_company = company
    user.ensure_authentication_token
    user.update_attributes(FactoryGirl.attributes_for(:user).reject{|k,v| ['password','password_confirmation','email'].include?(k.to_s)}, without_protection: true)
    sign_in user
    user
  end

  def set_event_results(event, results, autosave = true)
    event.result_for_kpi(Kpi.impressions).value = results[:impressions] if results.has_key?(:impressions)
    event.result_for_kpi(Kpi.interactions).value = results[:interactions] if results.has_key?(:interactions)
    event.result_for_kpi(Kpi.samples).value = results[:samples] if results.has_key?(:samples)
    values = event.result_for_kpi(Kpi.gender)
    values.detect{|r| r.kpis_segment.text == 'Male'}.value = results[:gender_male] if results.has_key?(:gender_male)
    values.detect{|r| r.kpis_segment.text == 'Female'}.value = results[:gender_female] if results.has_key?(:gender_female)

    values = event.result_for_kpi(Kpi.ethnicity)
    values.detect{|r| r.kpis_segment.text == 'Asian'}.value = results[:ethnicity_asian] if results.has_key?(:ethnicity_asian)
    values.detect{|r| r.kpis_segment.text == 'Native American'}.value = results[:ethnicity_native_american] if results.has_key?(:ethnicity_native_american)
    values.detect{|r| r.kpis_segment.text == 'Black / African American'}.value = results[:ethnicity_black] if results.has_key?(:ethnicity_black)
    values.detect{|r| r.kpis_segment.text == 'Hispanic / Latino'}.value = results[:ethnicity_hispanic] if results.has_key?(:ethnicity_hispanic)
    values.detect{|r| r.kpis_segment.text == 'White'}.value = results[:ethnicity_white] if results.has_key?(:ethnicity_white)

    values = event.result_for_kpi(Kpi.age)
    values.detect{|r| r.kpis_segment.text == '< 12'}.value = results[:age_12] if results.has_key?(:age_12)
    values.detect{|r| r.kpis_segment.text == '12 – 17'}.value = results[:age_12_17] if results.has_key?(:age_12_17)
    values.detect{|r| r.kpis_segment.text == '18 – 24'}.value = results[:age_18_24] if results.has_key?(:age_18_24)
    values.detect{|r| r.kpis_segment.text == '25 – 34'}.value = results[:age_25_34] if results.has_key?(:age_25_34)
    values.detect{|r| r.kpis_segment.text == '35 – 44'}.value = results[:age_35_44] if results.has_key?(:age_35_44)
    values.detect{|r| r.kpis_segment.text == '45 – 54'}.value = results[:age_45_54] if results.has_key?(:age_45_54)
    values.detect{|r| r.kpis_segment.text == '55 – 64'}.value = results[:age_55_64] if results.has_key?(:age_55_64)
    values.detect{|r| r.kpis_segment.text == '65+'}.value = results[:age_65] if results.has_key?(:age_65)

    event.save if autosave
  end

  def whithout_current_user
    user = User.current
    User.current = nil
    yield
  ensure
    User.current = user
  end

  def woorbook_from_last_export
    export = ListExport.last
    export.should_receive(:save).any_number_of_times.and_return(true)
    File.should_receive(:delete) do |path|
      yield Roo::Excelx.new(path)
    end
    export.export_list
  end
end