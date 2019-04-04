class BoardTicket < ApplicationRecord
  include RankedModel

  belongs_to :board
  belongs_to :ticket
  belongs_to :swimlane
  has_many :timesheets, dependent: :destroy
  has_many :release_board_tickets, dependent: :destroy
  has_many :releases, through: :release_board_tickets
  has_one :open_timesheet, -> { where(ended_at: nil) }, class_name: 'Timesheet'

  after_save :update_timesheet, if: :saved_change_to_swimlane_id?
  after_commit :update_github, on: :update, if: :saved_change_to_swimlane_id?

  scope :for_board, -> (board_id) { where(board_id: board_id) }
  scope :for_repo, -> (repo_id) { where(tickets: { repo_id: repo_id }) }
  scope :preloaded, -> { preload(:open_timesheet, ticket: [:repo, pull_requests: %i[repo]]) }

  ranks :swimlane_sequence, with_same: :swimlane_id

  alias_method :swimlane_position, :swimlane_sequence_position
  alias_method :swimlane_position=, :swimlane_sequence_position=

  attr_writer :update_remote

  def state_durations
    timesheets.each_with_object(Hash.new 0) do |timesheet, durations|
      durations[timesheet.swimlane.name] += timesheet.started_at.business_time_until(timesheet.ended_at || Time.now)
    end
  end

  def current_state_duration
    format_duration(state_durations[swimlane.name])
  end

  def time_since_last_transition
    format_duration(open_timesheet.started_at.business_time_until(Time.now))
  end

  def displayable_durations(board)
    durations = state_durations

    board.swimlanes.where(display_duration: true).map do |swimlane|
      next if durations[swimlane.name].zero?
      {
        id: swimlane.id,
        name: swimlane.name,
        duration: format_duration(durations[swimlane.name])
      }
    end.compact
  end

  private

  def update_remote?
    unless defined? @update_remote
      @update_remote = ENV['DO_NOT_SYNC_TO_GITHUB'].blank?
    end
    @update_remote
  end

  def format_duration(seconds)
    if seconds < 1.hour
      "< 1h"
    elsif seconds < 8.hours
      "#{(seconds / 1.hour).floor}h"
    else
      "#{(seconds / 8.hours).floor}d"
    end
  end

  def update_timesheet
    time_now = Time.now

    if open_timesheet
      open_timesheet.update_attributes(
        ended_at: time_now,
        after_swimlane: swimlane
      )
    end

    timesheets.create!(
      started_at: time_now,
      swimlane: swimlane,
      before_swimlane_id: attribute_before_last_save(:swimlane_id)
    )
  end

  def update_github
    return unless update_remote?

    # TODO: need to be able to recover if github does not respond,
    # possibly moving to a background job

    if swimlane_id == closed_swimlane.id
      Octokit.close_issue(ticket.repo.remote_url, ticket.remote_number)
    elsif attribute_before_last_save(:swimlane_id) == closed_swimlane.id
      Octokit.reopen_issue(ticket.repo.remote_url, ticket.remote_number)
    end

    Octokit.replace_all_labels(
      ticket.repo.remote_url,
      ticket.remote_number,
      new_github_labels
    )
  end

  def new_github_labels
    Octokit.labels_for_issue(
      ticket.repo.remote_url,
      ticket.remote_number
    ).
    map(&:name).
    reject { |label| label.start_with? 'status:' } +
    [ "status: #{swimlane.name.downcase}" ]
  end

  def closed_swimlane
    board.closed_swimlane
  end

end
