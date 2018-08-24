class TicketActions::Mergeability < TicketActions::Base
  def next_action
    case pull_request.merge_status
    when 'merge_conflicts'
      # owner
      negative 'Fix merge conflicts', urls: pull_request.html_url
    when 'merge_ok'
      # all
      positive 'Merge it!', urls: "#{pull_request.html_url}#partial-pull-merging"
    else # merge status unknown
      # all
      neutral 'Wait for merge check', urls: pull_request.html_url
    end
  end
end

