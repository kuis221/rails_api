module DeactivableHelper

  module ViewMethods
    def active_inactive_buttons(resource)
      content_tag(:div, class: 'btn-group') do
        link_to('Active', activate_event_path(resource), class: 'btn btn-small activate-event-btn'+(resource.active? ? ' btn-success active' : ''), remote: true)+
        link_to('Inactive', deactivate_event_path(resource), class: 'btn btn-small deactivate-event-btn'+(resource.active? ? '' : ' btn-danger active'), remote: true)
      end
    end
  end


  module InstanceMethods
    include DeactivableHelper::ViewMethods
    def deactivate
      if resource.active?
        resource.deactivate!
      end
    end

    def activate
      unless resource.active?
        resource.activate!
      end
      render 'deactivate'
    end
  end


  def self.included(receiver)
    receiver.send(:include,  InstanceMethods)
  end
end
