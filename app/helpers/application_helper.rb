module ApplicationHelper
  def next_action_button(pull_request, user: nil, **options)
    next_action = TicketActions.next_action_for(pull_request, user: user)
    return '' if next_action.blank?

    btn_class =
      case next_action.type
      when :positive then 'btn-success'
      when :warning, :caution then 'btn-caution'
      when :negative then 'btn-danger'
      else 'btn-default'
      end

    options[:class] = ['btn', btn_class, *options[:class]]

    if next_action.urls.many?
      options[:type] = 'button'
      options[:class] << 'dropdown-toggle'
      options.deep_merge!(data: { toggle: 'dropdown' })

      button = button_tag(options) do
        h(next_action.text) + '&nbsp;'.html_safe + content_tag(:span, '', class: 'caret')
      end

      content_tag(:div, class: 'dropdown') do
        button + url_dropdown_menu(next_action)
      end
    else
      options[:target] = :_blank
      link_to next_action.text, next_action.url.to_s, options
    end
  end

  def pull_request_icon(pull_request)
    if pull_request.merged?
      octicon 'git-merge', class: 'is-merged'
    else
      octicon 'git-pull-request', class: (pull_request.open? ? 'text-success' : 'text-danger')
    end
  end

  private

  def url_dropdown_menu(action)
    items = action.urls.map do |url|
      content_tag(:li) do
        link_to url.title.presence || action.text, url.url, target: :_blank
      end
    end

    content_tag(:ul, class: 'dropdown-menu dropdown-menu-right') do
      safe_join(items)
    end
  end
end
