module ApplicationHelper
  def hide_container?
    @hide_container
  end

  def polyfill_url
    query_string = {
      features: 'fetch|gated'
    }

    minify = Rails.env.production? ? '.min' : ''

    "https://cdn.polyfill.io/v2/polyfill#{minify}.js?#{query_string.to_query}"
  end

  def next_action_button(pull_request, user: nil, **options)
    next_action = TicketActions.next_action_for(pull_request, user: user)
    return '' if next_action.blank?

    btn_class =
      case next_action.type
      when :positive then 'green'
      when :warning then 'yellow'
      when :caution then 'basic yellow'
      when :negative then 'red'
      else 'basic'
      end

    options[:class] = ['ui button next-action-btn', *btn_class, *options[:class]]

    if next_action.urls.many?
      options[:class] << 'simple dropdown'

      button = content_tag(:span, next_action.text, class: 'text') +
        '&nbsp;'.html_safe +
        content_tag(:i, '', class: 'dropdown icon')

      content_tag(:div, options) do
        button + url_dropdown_menu(next_action)
      end
    else
      options[:target] = :_blank
      link_to next_action.text, next_action.url.to_s, options
    end
  end

  private

  def url_dropdown_menu(action)
    items = action.urls.map do |url|
      link_to url.title.presence || action.text, url.url, target: :_blank, class: 'item'
    end

    content_tag(:div, class: 'menu') do
      safe_join(items)
    end
  end
end
