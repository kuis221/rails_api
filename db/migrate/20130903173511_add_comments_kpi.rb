class AddCommentsKpi < ActiveRecord::Migration
  def up
    if Kpi.comments.nil?
      Kpi.create({name: 'Comments', kpi_type: 'comments', description: 'Total number of comments from event audience', capture_mechanism: 'integer', company_id: nil, 'module' => 'comments'}, without_protection: true)
    end
  end

  def down
    Kpi.find_by_name_and_module('Comments', 'comments').destroy_all
  end
end
