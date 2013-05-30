module DeactivableHelper

  module ViewMethods
    def active_inactive_buttons(resource, message=nil)
      content_tag(:div, class: 'btn-group active-deactive-toggle') do
        link_to('Active', [:activate, resource], class: 'btn btn-small activate-'+resource.class.name.downcase+'-btn'+(resource.active? ? ' btn-success active' : ''), remote: true)+
        link_to('Inactive', [:deactivate, resource], class: 'btn btn-small deactivate-'+resource.class.name.downcase+'-btn'+(resource.active? ? '' : ' btn-danger active'), confirm: message, remote: true)
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
