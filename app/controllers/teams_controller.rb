class TeamsController < InheritedResources::Base
  respond_to :js, only: :new

  respond_to_datatables do
    columns [
      {:attr => :name, :column_name => 'teams.name', :searchable => true},
      {:attr => :description ,:column_name => 'teams.description', :searchable => true},
    ]
  end

end
