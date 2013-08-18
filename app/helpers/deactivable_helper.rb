module DeactivableHelper

  module ViewMethods
    def active_inactive_buttons(resource, message=nil)
      if resource.active?
        link_to(content_tag(:i, '', class: 'icon-check-sign'),  [:deactivate, resource], class: 'active-toggle-btn-'+resource.class.name.underscore.downcase+'-'+resource.id.to_s, confirm: message, remote: true)
      else
        link_to(content_tag(:i, '', class: 'icon-remove-sign'), [:activate, resource], class: 'active-toggle-btn-'+resource.class.name.underscore.downcase+'-'+resource.id.to_s, remote: true)
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
