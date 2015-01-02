class Results::AttendanceController < ApplicationController
  helper_method :return_path

  def index
    @states = Country.new('US').states.map { |code, data| ["#{code} (#{data['name']})", data['name']] }
  end

  def map
  end

  def return_path
    results_reports_path
  end
end
