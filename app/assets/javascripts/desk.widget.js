DESK = window.DESK || {};
(function () {
    if (DESK && DESK.Widget) return;
    DESK.Widget = function (opts) {
        this.init(opts)
    };
    ASSISTLY = window.ASSISTLY || {};
    ASSISTLY.Widget = DESK.Widget;
    (function () {
        DESK.Widget.ID_COUNTER = 0;
        DESK.Widget.prototype = function () {
            var new_chat_path = "/customer/widget/chats/new";
            var new_email_path = "/customer/widget/emails/new";
            var chat_sprite_path = "/assets/launch_chat_sprite.png";
            var email_sprite_path = "/assets/launch_email_sprite.png";
            var chat_sprite_path_ssl = "https://d3j15y3zsn7b4t.cloudfront.net/images/customer/widget/chat/launch_chat_sprite.png";
            var email_sprite_path_ssl = "https://d3j15y3zsn7b4t.cloudfront.net/images/customer/widget/email/launch_email_sprite.png";
            var agent_check_path = "/customer/agent_online_check";
            return {
                init: function (opts) {
                    this._widgetNumber = ++ASSISTLY.Widget.ID_COUNTER;
                    this._setWidgetType(opts.type);
                    var locale_code = ((opts.fields || {}).customer || {}).locale_code;
                    if (locale_code) if (this._isChatWidget) new_chat_path = new_chat_path.replace(/customer/, "customer/" + locale_code);
                    else if (this._isEmailWidget) new_email_path = new_email_path.replace(/customer/, "customer/" + locale_code);
                    this._secure = opts.secure || window.location.protocol == "https:";
                    this._site = opts.site;
                    this._port = opts.port || 80;
                    if (opts.port) this._base_url = (this._secure ? "https://" : "http://") + this._site + (this._secure ? "" : ":" + this._port);
                    else this._base_url = (this._secure ? "https://" : "http://") + this._site;
                    this._widgetPopupWidth = opts.popupWidth || 640;
                    this._widgetPopupHeight = opts.popupHeight || 700;
                    this._siteAgentCount = -1;
                    this._siteAgentRoutingCount = -1;
                    this._widgetDisplayMode = opts.displayMode || 0;
                    this._offerAlways = false;
                    this._offerRoutingAgentsAvailable = true;
                    this._offerAgentsOnline = false;
                    this._offerEmailIfChatUnavailable = false;
                    this._widgetID = opts.id || "assistly-widget-" + this._widgetNumber;
                    if (!opts.id) document.write('<span class="assistly-widget" id="' + this._widgetID + '"></span>');
                    this.widgetDOM = document.getElementById(this._widgetID);
                    this.setFeatures(opts.features);
                    if (opts.fields) {
                        this._ticketFields = opts.fields.ticket;
                        this._interactionFields = opts.fields.interaction;
                        this._customerFields = opts.fields.customer;
                        this._emailFields = opts.fields.email;
                        this._chatFields = opts.fields.chat
                    } else {
                        this._ticketFields = [];
                        this._interactionFields = [];
                        this._customerFields = [];
                        this._emailFields = [];
                        this._chatFields = []
                    }
                    return this
                },
                _setWidgetType: function (type) {
                    this._isEmailWidget = false;
                    this._isChat = false;
                    this._type = type;
                    switch (type) {
                    case "email":
                        this._isEmailWidget = true;
                        break;
                    case "chat":
                        this._isChatWidget = true;
                        break;
                    default:
                        this._isEmailWidget = true
                    }
                    return this
                },
                setFeatures: function (features) {
                    if (features) {
                        if (!(typeof features.offerAlways === "undefined")) this._offerAlways = features.offerAlways;
                        if (!(typeof features.offerRoutingAgentsAvailable === "undefined")) this._offerRoutingAgentsAvailable = features.offerRoutingAgentsAvailable;
                        if (!(typeof features.offerAgentsOnline === "undefined")) this._offerAgentsOnline = features.offerAgentsOnline;
                        if (!(typeof features.offerEmailIfChatUnavailable === "undefined")) this._offerEmailIfChatUnavailable = features.offerEmailIfChatUnavailable
                    }
                    return this
                },
                setSiteAgentCount: function (data) {
                    this._siteAgentCount = data.online_agents;
                    this._siteAgentRoutingCount = data.routing_agents;
                    this.render()
                },
                _buildBaseButton: function () {
                    var result = "";
                    var sprite_path = "";
                    var action_path = "";
                    var show_disabled = false;
                    var ticket_params = "";
                    var interaction_params = "";
                    var customer_params = "";
                    var email_params = "";
                    var chat_params = "";
                    var params = "";
                    if (this._ticketFields) for (param in this._ticketFields) ticket_params += "ticket[" + escape(param) + "]=" + escape(this._ticketFields[param]) + "&";
                    if (this._interactionFields) for (param in this._interactionFields) interaction_params += "interaction[" + escape(param) + "]=" + escape(this._interactionFields[param]) + "&";
                    if (this._customerFields) for (param in this._customerFields) customer_params += "customer[" + escape(param) + "]=" + escape(this._customerFields[param]) + "&";
                    if (this._emailFields) for (param in this._emailFields) email_params += "email[" + escape(param) + "]=" + escape(this._emailFields[param]) + "&";
                    if (this._chatFields) for (param in this._chatFields) chat_params += "chat[" + escape(param) + "]=" + escape(this._chatFields[param]) + "&";
                    params = ticket_params + interaction_params + email_params + chat_params + customer_params;
                    if (this._isChatWidget) {
                        sprite_path = this._secure ? chat_sprite_path_ssl : chat_sprite_path;
                        action_path = new_chat_path;
                        if (!this._offerAlways) {
                            if (this._offerRoutingAgentsAvailable && this._siteAgentRoutingCount < 1) show_disabled = true;
                            if (this._offerAgentsOnline && this._siteAgentCount < 1) show_disabled = true
                        }
                        if (!this._offerAlways && !this._offerRoutingAgentsAvailable && !this._offerAgentsOnline) show_disabled = true;
                        if (show_disabled && this._offerEmailIfChatUnavailable) {
                            this._isChatWidget = false;
                            this._isEmailWidget = true
                        }
                    }
                    if (this._isEmailWidget) {
                        sprite_path = this._secure ? email_sprite_path_ssl : email_sprite_path;
                        action_path = new_email_path
                    }
                    action_path += "?" + params;
                    if (!show_disabled) {
                        if (this._widgetDisplayMode == 0) result = '              <a href="#"               class="a-desk-widget a-desk-widget-' + this._type + '"               style="text-decoration:none;width:65px;display:inline-block;min-height:22px;background: url(' + sprite_path + ') no-repeat scroll 0 0px transparent;"               onmouseover="this.style.backgroundPosition=\'0 -20px\'"               onmouseout="this.style.backgroundPosition=\'0 0px\'"               onclick="tracking(\'email\'); window.open(\'' + this._base_url + action_path + "', 'assistly_chat','resizable=1, status=0, toolbar=0,width=" + this._widgetPopupWidth + ",height=" + this._widgetPopupHeight + "')\">&nbsp;</a>";
                        if (this._widgetDisplayMode == 1) result = '              <a href="' + this._base_url + action_path + '"               class="a-desk-widget a-desk-widget-' + this._type + '"               style="text-decoration:none;width:65px;display:inline-block;min-height:22px;background: url(' + sprite_path + ') no-repeat scroll 0 0px transparent;"               onclick="tracking(\'chat\');" onmouseover="this.style.backgroundPosition=\'0 -20px\'"               onmouseout="this.style.backgroundPosition=\'0 0px\'"               >&nbsp;</a>'
                    } else result = '            <span style="width:65px;display:inline-block;min-height:22px;background: url(' + sprite_path + ') no-repeat scroll 0 -40px transparent;">&nbsp;</span>';
                    return result
                },
                _renderChatWidget: function () {
                    if (this._siteAgentCount < 0) {
                        var that = this;
                        url = this._base_url + agent_check_path;
                        jQuery.getJSON(url + "?callback=?", function (data) {
                            if (data) that.setSiteAgentCount(data)
                        })
                    } else this.widgetDOM.innerHTML = this._buildBaseButton();
                    return this
                },
                _renderEmailWidget: function () {
                    this.widgetDOM.innerHTML = this._buildBaseButton();
                    return this
                },
                render: function () {
                    if (this._isChatWidget) this._renderChatWidget();
                    if (this._isEmailWidget) this._renderEmailWidget();
                    if (this._widgetDisplayMode == 1) jQuery("#" + this._widgetID + " a").each(function () {
                        $(this).fancybox({
                            "width": this._widgetPopupWidth,
                            "height": this._widgetPopupHeight,
                            "type": "iframe",
                            "hideOnOverlayClick": false,
                            "centerOnScroll": true
                        })
                    });
                    return this
                }
            }
        }()
    })()
})();
(function ($) {
    $.autolink = function (html, target) {
        target = target || "_blank";
        html = html || "";
        var re_proto = /\b([\w+.:-]+:\/\/)|mailto:/i,
            re = new RegExp("(\\b(?:([\\w+.:-]+:)//|www.|mailto:)(([\\w.\\-+]+(:\\w+)?@)?[-\\w]+(?:\\.[-\\w]+)*(?::\\d+)?(?:/(?:[~\\w\\+@%=\\(\\)-]|(?:[,.;:#'][^\\s$]))*)*(?:\\?[\\w\\+@%&-=.;:/-\\[\\]]+)?(?:\\#[\\w\\-]*)?)([[^$.*+?=!:|\\/()[]{}]]|<|$|))", "g");
        return html.replace(re, function (str) {
            var href = str,
                a_target = target;
            if (!re_proto.test(str)) href = "http://" + href;
            else if (/mailto:/i.test(str)) a_target = "_self";
            return $("<a/>", {
                target: a_target,
                href: href
            }).html(str).outerHTML()
        })
    };
    $.fn.highlight = function (text, o) {
        var safe_text = text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
        return this.each(function () {
            var replace = o || '<span class="highlight">$1</span>';
            $(this).html($(this).html().replace(new RegExp("(" + safe_text + '(?![\\w\\s?&.\\/;#~%"=-]*>))', "ig"), replace))
        })
    };
    $.fn.autolink_old = function (target) {
        target = target || "_self";
        return this.each(function () {
            var re = /((http|https|ftp):\/\/[\w?=&.\/-;#~%-]+(?![\w\s?&.\/;#~%"=-]*>))/g;
            $(this).html($(this).html().replace(re, '<a target="' + target + '" href="$1">$1</a> '))
        })
    };
    $.fn.mailto = function () {
        return this.each(function () {
            var re = /(([a-z0-9*._+]){1,}\@(([a-z0-9]+[-]?){1,}[a-z0-9]+\.){1,}([a-z]{2,4}|museum)(?![\w\s?&.\/;#~%"=-]*>))/g;
            $(this).html($(this).html().replace(re, '<a href="mailto:$1">$1</a>'))
        })
    };
    $.fn.autolink = function (target) {
        return this.each(function () {
            var $this = $(this),
                html = $.autolink($this.html(), target);
            $this.html(html)
        })
    }
})(jQuery);