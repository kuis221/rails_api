collection @surveys

attributes :id, :active, :created_at, :updated_at

child :surveys_answers do
  attributes :id, :kpi_id, :question_id, :brand_id, :answer
end