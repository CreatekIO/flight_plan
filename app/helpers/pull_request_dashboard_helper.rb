module PullRequestDashboardHelper
  def status_label(text, options = {})
    text = text.downcase

    type =
      case text
      when 'approved', 'success' then 'green'
      when 'changes_requested' then 'yellow'
      when 'failure', 'error' then 'red'
      end

    options[:class] = ['ui', *type, 'label', *options[:class]]

    content_tag :div, text.humanize.downcase, options
  end

  GITHUB_AVATAR_URL = 'https://github.com/%{username}.png'.freeze

  def avatar_tag(username, **options)
    return '' if username.blank?

    options[:class] = ['ui avatar image', *options[:class]]
    avatar_url = format(GITHUB_AVATAR_URL, username: username)

    image_tag avatar_url, alt: username, **options
  end

  def short_time_distance(time)
    distance = ((Time.now.utc - time.utc) / 60).floor

    case distance
    when 0..(1.hour) then "#{distance}m"
    when (1.hour + 1.second)..(1.day) then "#{distance / 1.hour}h"
    when (1.day + 1.second)..(1.week) then "#{distance / 1.day}d"
    else "#{distance / 1.week}w"
    end
  end
end
