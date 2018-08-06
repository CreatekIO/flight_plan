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
    options[:target] = :_blank

    link_to next_action.text, next_action.url, options
  end
end
