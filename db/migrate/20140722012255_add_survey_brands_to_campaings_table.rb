class AddSurveyBrandsToCampaingsTable < ActiveRecord::Migration
  def change
    add_column :campaigns, :survey_brand_ids, :integer, default: [], array: true
  end
end
