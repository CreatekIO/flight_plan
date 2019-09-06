class FixDataIntegrityOfTimesheets < ActiveRecord::Migration["4.2"]
  LABEL_EVENTS = %w[labeled unlabeled].freeze
  PREFIX = 'status:'.freeze

  def up
    # Some FlightPlan tickets are too messed up to fix
    ids_with_many_open_timesheets = Timesheet
      .joins(board_ticket: :repo)
      .where.not(repos: { remote_url: 'CreatekIO/flight_plan' })
      .group(:board_ticket_id)
      .where(ended_at: nil)
      .having('count_all > 1')
      .count
      .keys

    ids_with_wrong_open_timesheet = BoardTicket
      .joins(:ticket, :repo)
      .where.not(repos: { remote_url: 'CreatekIO/flight_plan' })
      .joins('INNER JOIN timesheets open_ts ON open_ts.board_ticket_id = board_tickets.id AND open_ts.ended_at IS NULL')
      .where('open_ts.swimlane_id != board_tickets.swimlane_id')
      .distinct
      .pluck(:id)

    ids = (ids_with_many_open_timesheets + ids_with_wrong_open_timesheet).uniq

    say "Identified #{ids.join(', ')} (#{ids.size} total) as problematic"

    swimlanes_by_label = Swimlane.joins(board: :board_tickets).where(board_tickets: { id: ids }).index_by do |swimlane|
      [swimlane.board_id, swimlane.name.downcase]
    end

    board_tickets = BoardTicket.where(id: ids).includes(ticket: :repo)

    details = board_tickets.map do |board_ticket|
      slug = to_slug(board_ticket)

      events = say_with_time("Fetching #{slug.join('/')} from API...") { Octokit.issue_events(*slug) }
      new_timesheets = to_timesheets(board_ticket, events, swimlanes_by_label)

      [board_ticket, slug, new_timesheets]
    end

    BoardTicket.transaction do
      details.each do |(board_ticket, slug, new_timesheets)|
        say_with_time "#{slug.join('/')}: replacing timesheets with #{new_timesheets.size} records" do
          board_ticket.timesheets.delete_all
          new_timesheets.each(&:save!)
        end
      end
    end
  end

  private

  def to_slug(board_ticket)
    ticket = board_ticket.ticket
    repo = ticket.repo

    [repo.remote_url, ticket.remote_number]
  end

  def to_timesheets(board_ticket, gh_events, swimlanes_by_label)
    events = aggregate_events(board_ticket.ticket, gh_events)

    events.map.with_index do |event, index|
      date, label = event
      next_event = events[index + 1]
      prev_event = index.zero? ? nil : events[index - 1]

      board_ticket.timesheets.build(
        started_at: date,
        ended_at: next_event.try(:first),
        swimlane: swimlanes_by_label[
          [board_ticket.board_id, label_to_swimlane_name(label)]
        ],
        before_swimlane: swimlanes_by_label[
          [board_ticket.board_id, label_to_swimlane_name(prev_event.try(&:last))]
        ],
        after_swimlane: swimlanes_by_label[
          [board_ticket.board_id, label_to_swimlane_name(next_event.try(&:last))]
        ],
      )
    end
  end

  def label_to_swimlane_name(label)
    return unless label

    label.remove(/\**status: /)
  end

  def aggregate_events(ticket, gh_events)
    events = summarise_events(gh_events)
    default_proc = events.default_proc

    events = events.sort_by(&:first).to_h
    events.default_proc = default_proc

    if events.first.first != ticket.remote_created_at.utc
      events[ticket.remote_created_at.utc] << [:added, '**status: backlog']
    end

    events = events.sort_by(&:first).to_h
    events.default_proc = default_proc

    events.map do |time, labels|
      label = if labels.one? && labels.first.first == :added
        labels.first.last
      elsif labels.one? && labels.first.first == :removed
        nil
      elsif labels.size == 2 && labels.map(&:first).sort == %i[added removed]
        labels.find { |(state)| state == :added }.last
      elsif labels.all? { |(state)| state == :added }
        labels.find { |(state)| state == :added }.last
      else
        grouped = labels.group_by(&:last)
        grouped.find { |(_, group)| group.one? && group.first.first == :added }.first or raise 'no label'
      end

      next unless label

      [time, label]
    end.compact
  end

  def summarise_events(gh_events)
    current_status_labels = Set.new

    gh_events.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |gh_event, labellings|
      label = if gh_event.event.in?(LABEL_EVENTS)
        gh_event.label.name.sub(/bug ?backlog/, 'backlog - bugs')
      end

      case gh_event.event
      when 'labeled'
        next(labellings) unless label.start_with?('status:')

        labellings[gh_event.created_at] << [:added, label]
        current_status_labels << label
      when 'unlabeled'
        next(labellings) unless gh_event.label.name.start_with?('status:')

        current_status_labels.delete(label)
        labellings[gh_event.created_at] << [:removed, label]
      when 'closed'
        labellings[gh_event.created_at] << [:added, '*status: deploying - done']
      when 'reopened'
        labellings[gh_event.created_at] << [:added, '*status: backlog']
      end

      raise current_status_labels.inspect if current_status_labels.many?
    end
  end

end
