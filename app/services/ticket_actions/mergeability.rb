class TicketActions::Mergeability < TicketActions::Base
  next_actions do |c|
    case pull_request.merge_status
    when 'merge_conflicts'
      # owner
      c.negative 'Fix merge conflicts', urls: html_url, user_ids: owner_id
      c.caution 'Merge conflicts', urls: html_url, user_ids: team_ids
    when 'merge_ok'
      # all
      c.positive 'Merge it!', urls: "#{html_url}#partial-pull-merging"
    else # merge status unknown
      # all
      c.neutral 'Wait for merge check', urls: html_url
    end
  end
end

