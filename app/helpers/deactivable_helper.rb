module DeactivableHelper

  module ViewMethods
    def active_inactive_buttons(resource, message=nil)
      has_parent ||= respond_to?(:parent?) && parent?
      model_sytem_name = resource.class.name.underscore
      humanized_name = resource.class.model_name.human.downcase
      if resource.active?
        link_to(content_tag(:i, '', class: 'icon-rounded-disable'),  url_for(params.merge(action: :deactivate, id: resource.id)), class: 'toggle-inactive active-toggle-btn-'+resource.class.name.underscore.downcase+'-'+resource.id.to_s, confirm: message, remote: true, title: I18n.t('confirmation.deactivate'), confirm: I18n.t('confirmation.deactivate_confirm_message', model: humanized_name))
      else
        link_to(content_tag(:i, '', class: 'icon-rounded-ok'), url_for(params.merge(action: :activate, id: resource.id)), class: 'toggle-active active-toggle-btn-'+resource.class.name.underscore.downcase+'-'+resource.id.to_s, remote: true, title: I18n.t('confirmation.activate'))
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
