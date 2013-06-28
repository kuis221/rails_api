object false
extends "application/index"

if params[:page].nil? || params[:page] == '1'
  node :unassigned do
    status_counters['unassigned']
  end

  node :completed do
    status_counters['completed']
  end

  node :assigned do
    status_counters['assigned']
  end

  node :late do
    status_counters['late']
  end
end