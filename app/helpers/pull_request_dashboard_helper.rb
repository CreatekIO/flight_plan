module PullRequestDashboardHelper
  def bs_label(text)
    text = text.downcase

    type =
      case text
      when 'approved', 'success' then 'success'
      when 'changes_requested' then 'warning'
      when 'failure', 'error' then 'danger'
      else 'default'
      end

    content_tag :span, text.humanize.downcase, class: "label label-#{type}"
  end

  GITHUB_AVATAR_URL = "https://github.com/%{username}.png".freeze

  def avatar_tag(username, **options)
    return '' if username.blank?

    options[:class] = ['avatar', *options[:class]]
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
