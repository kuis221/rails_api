module DeactivableHelper
  module ViewMethods
    def active_inactive_buttons(resource, _message = nil)
      if resource.active?
        link_to(content_tag(:i, '', class: 'icon-rounded-disable'),  url_for(params.merge(action: :deactivate, id: resource.id)), class: 'toggle-inactive active-toggle-btn-' + resource.class.name.underscore.gsub('/', '_').downcase + '-' + resource.id.to_s, remote: true, title: I18n.t('confirmation.deactivate'), data: { confirm: I18n.t('confirmation.deactivate_confirm_message', model: resource.class.model_name.human.downcase) })
      else
        link_to(content_tag(:i, '', class: 'icon-rounded-ok'), url_for(params.merge(action: :activate, id: resource.id)), class: 'toggle-active active-toggle-btn-' + resource.class.name.underscore.gsub('/', '_').downcase + '-' + resource.id.to_s, remote: true, title: I18n.t('confirmation.activate'))
      end
    end
  end

  module InstanceMethods
    include DeactivableHelper::ViewMethods
    def deactivate
      resource.deactivate! if resource.active?
    end

    def activate
      resource.activate! unless resource.active?
      render 'deactivate'
    end
  end

  def self.included(receiver)
    receiver.send(:include,  InstanceMethods)
  end
end
