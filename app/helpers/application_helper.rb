module ApplicationHelper
  def next_action_button(pull_request, options = {})
    next_action = TicketActions.for(pull_request).first
    return '' if next_action.blank?

    btn_type =
      case next_action.type
      when :positive then 'success'
      when :warning then 'warning'
      when :negative then 'danger'
      else 'default'
      end

    options[:class] = ["btn btn-#{btn_type}", *options[:class]]

    if next_action.urls.many?
      options[:type] = 'button'
      options[:class] << 'dropdown-toggle'
      options.deep_merge!(data: { toggle: 'dropdown' })

      content_tag(:div, class: 'dropdown') do
        button_tag(options) do
          h(next_action.text) + '&nbsp;'.html_safe + content_tag(:span, '', class: 'caret')
        end + content_tag(:ul, class: 'dropdown-menu dropdown-menu-right') do
          safe_join(next_action.urls.map do |url|
            content_tag(:li) do
              link_to url.title.presence || next_action.text, url.url, target: :_blank
            end
          end)
        end
      end
    else
      options[:target] = :_blank
      link_to next_action.text, next_action.url.to_s, options
    end
  end
end
