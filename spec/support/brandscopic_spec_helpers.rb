module BrandscopiSpecHelpers
  def sign_in_as_user(company_user=nil)
    if company_user.present?
      company = company_user.company
      user = company_user.user
    else
      company = FactoryGirl.create(:company_with_user)
      user = company.company_users.first.user
    end
    User.current = user
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
    result = event.result_for_kpi(Kpi.gender)
    segments = Kpi.gender.kpis_segments
    value = {}
    value[segments.detect{|s| s.text == 'Male'}.id]  = results[:gender_male] if results.has_key?(:gender_male)
    value[segments.detect{|s| s.text == 'Female'}.id] = results[:gender_female] if results.has_key?(:gender_female)
    result.value = value

    result = event.result_for_kpi(Kpi.ethnicity)
    segments = Kpi.ethnicity.kpis_segments
    value = {}
    value[segments.detect{|s| s.text == 'Asian'}.id] = results[:ethnicity_asian] if results.has_key?(:ethnicity_asian)
    value[segments.detect{|s| s.text == 'Native American'}.id] = results[:ethnicity_native_american] if results.has_key?(:ethnicity_native_american)
    value[segments.detect{|s| s.text == 'Black / African American'}.id] = results[:ethnicity_black] if results.has_key?(:ethnicity_black)
    value[segments.detect{|s| s.text == 'Hispanic / Latino'}.id] = results[:ethnicity_hispanic] if results.has_key?(:ethnicity_hispanic)
    value[segments.detect{|s| s.text == 'White'}.id] = results[:ethnicity_white] if results.has_key?(:ethnicity_white)
    result.value = value

    result = event.result_for_kpi(Kpi.age)
    segments = Kpi.age.kpis_segments
    value = {}
    value[segments.detect{|s| s.text == '< 12'}.id] = results[:age_12] if results.has_key?(:age_12)
    value[segments.detect{|s| s.text == '12 – 17'}.id] = results[:age_12_17] if results.has_key?(:age_12_17)
    value[segments.detect{|s| s.text == '18 – 24'}.id] = results[:age_18_24] if results.has_key?(:age_18_24)
    value[segments.detect{|s| s.text == '25 – 34'}.id] = results[:age_25_34] if results.has_key?(:age_25_34)
    value[segments.detect{|s| s.text == '35 – 44'}.id] = results[:age_35_44] if results.has_key?(:age_35_44)
    value[segments.detect{|s| s.text == '45 – 54'}.id] = results[:age_45_54] if results.has_key?(:age_45_54)
    value[segments.detect{|s| s.text == '55 – 64'}.id] = results[:age_55_64] if results.has_key?(:age_55_64)
    value[segments.detect{|s| s.text == '65+'}.id] = results[:age_65] if results.has_key?(:age_65)
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
    require "rexml/document"
    export = ListExport.last
    expect(export).to receive(:save).at_least(:once).and_return(true)
    expect(File).to receive(:delete) do |path|
      file = File.new( path )
      yield REXML::Document.new(file)
    end
    export.export_list
  end

  def csv_from_last_export
    require "rexml/document"
    export = ListExport.last
    allow(export).to receive(:save).and_return(true)
    expect(File).to receive(:delete) do |path|
      file = File.new( path )
      yield REXML::Document.new(file)
    end
    export.export_list
  end
end

RSpec.configure do |config|
  config.include BrandscopiSpecHelpers
end
