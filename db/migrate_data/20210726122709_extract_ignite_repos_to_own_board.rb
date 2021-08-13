class ExtractIgniteReposToOwnBoard < ActiveRecord::Migration["4.2"]
  def up
    @old_board = Board.find_by!(name: 'Corporate Rewards')

    User.transaction do
      run :create_board
      run :copy_swimlanes

      run :update_deploy_swimlane

      run :move_repos_to_new_board
      run :move_board_tickets_to_new_board
      run :move_timesheets_to_new_swimlanes
    end
  end

  private

  attr_reader :old_board, :new_board, :swimlane_id_map, :repos

  def run(name)
    say_with_time(name.to_s.humanize) { send(name) }
  end

  def copy_record(record)
    record.class.new(record.attributes.except('id', 'created_at', 'updated_at')).tap do |new_record|
      yield(new_record, record) if block_given?
    end
  end

  def repo_ids
    @repo_ids ||= repos.map(&:id)
  end

  def create_board
    @new_board = Board.find_or_create_by!(name: 'Ignite') do |board|
      board.additional_branches_regex = '^configuration_changes$'
    end
  end

  def copy_swimlanes
    @swimlane_id_map = old_board.swimlanes.each_with_object({}) do |old_swimlane, swimlanes|
      new_swimlane = Swimlane.find_by(
        board_id: new_board.id,
        name: old_swimlane.name
      ) || duplicate_swimlane(old_swimlane)

      swimlanes[old_swimlane.id] = new_swimlane.id
    end
  end

  def duplicate_swimlane(old_swimlane)
    copy_record(old_swimlane) do |new_swimlane|
      new_swimlane.board_id = new_board.id
      new_swimlane.save!
    end
  end

  def update_deploy_swimlane
    new_deploy_swimlane_id = swimlane_id_map.fetch(old_board.deploy_swimlane_id)

    new_board.update_attributes!(deploy_swimlane_id: new_deploy_swimlane_id)
  end

  def move_repos_to_new_board
    @repos = Repo.where(Repo.arel_table[:name].matches('%Ignite%'))

    say "Found #{repos.length}: #{repos.map { |repo| repo.slice(:id, :slug) }.inspect}"

    repos.each do |repo|
      BoardRepo.where(repo: repo, board: old_board).each do |board_repo|
        board_repo.update_attributes!(board_id: new_board.id)
      end
    end
  end

  def move_board_tickets_to_new_board
    board_tickets = BoardTicket.joins(:ticket).where(tickets: { repo_id: repo_ids }, board: old_board)

    # Update via SQL to avoid triggering callbacks,
    # and in bulk to reduce duration of long-running transaction
    swimlane_id_map.each do |old_swimlane_id, new_swimlane_id|
      board_tickets.where(swimlane_id: old_swimlane_id).update_all(
        board_id: new_board.id,
        swimlane_id: new_swimlane_id,
        updated_at: Time.now
      )
    end
  end

  def move_timesheets_to_new_swimlanes
    timesheets = Timesheet.joins(board_ticket: :ticket).where(tickets: { repo_id: repo_ids })

    swimlane_id_map.each do |old_swimlane_id, new_swimlane_id|
      %i[swimlane_id before_swimlane_id after_swimlane_id].each do |column|
        timesheets.where(column => old_swimlane_id).update_all(column => new_swimlane_id)
      end
    end
  end
end
