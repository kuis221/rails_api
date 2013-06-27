object false
extends "application/index"

if params[:page] == '1'
  node :description do
   describe_filters
  end
end