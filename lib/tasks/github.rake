namespace :github do
  task :pull => :environment do
    fp = Repo.find_or_create_by(name: 'FlightPlan', remote_url: 'CreatekIO/flight_plan')
    myr = Repo.find_or_create_by(name: 'MyRewards', remote_url: 'CorporateRewards/myrewards')
    gps = Repo.find_or_create_by(name: 'GPS', remote_url: 'CorporateRewards/redstone')

    fp_board = Board.find_or_create_by(name: 'Flight Plan') do |board|
      board.repos << fp
      board.save
    end

    cr_board = Board.find_or_create_by(name: 'Corporate Rewards') do |board|
      board.repos << myr
      board.repos << gps
      board.save
    end

    [fp_board, cr_board].each do |board|
      position = 0
      backlog = Swimlane.find_or_create_by(board: board, name: 'Backlog', position: position+=1)
      bugs = Swimlane.find_or_create_by(board: board, name: 'Backlog - Bugs', position: position+=1)
      plan = Swimlane.find_or_create_by(board: board, name: 'Planning', position: position+=1)
      plan_done = Swimlane.find_or_create_by(board: board, name: 'Planning - DONE', position: position+=1)
      dev = Swimlane.find_or_create_by(board: board, name: 'Development', display_duration: true, position: position+=1)
      cr = Swimlane.find_or_create_by(board: board, name: 'Code Review', display_duration: true, position: position+=1)
      cr_done = Swimlane.find_or_create_by(board: board, name: 'Code Review - DONE', display_duration: true, position: position+=1)
      accept = Swimlane.find_or_create_by(board: board, name: 'Acceptance', display_duration: true, position: position+=1)
      accept_done = Swimlane.find_or_create_by(board: board, name: 'Acceptance - DONE', display_duration: true, position: position+=1)
      deploy = Swimlane.find_or_create_by(board: board, name: 'Deploying', display_duration: true, position: position+=1)
      done = Swimlane.find_or_create_by(board: board, name: 'Deploying - DONE', position: position+=1)

      SwimlaneTransition.find_or_create_by(swimlane: backlog, transition: bugs)
      SwimlaneTransition.find_or_create_by(swimlane: backlog, transition: plan)
      SwimlaneTransition.find_or_create_by(swimlane: backlog, transition: done)

      SwimlaneTransition.find_or_create_by(swimlane: bugs, transition: plan)
      SwimlaneTransition.find_or_create_by(swimlane: bugs, transition: done)

      SwimlaneTransition.find_or_create_by(swimlane: plan, transition: plan_done)
      SwimlaneTransition.find_or_create_by(swimlane: plan, transition: done)

      SwimlaneTransition.find_or_create_by(swimlane: plan_done, transition: dev)
      SwimlaneTransition.find_or_create_by(swimlane: plan_done, transition: done)

      SwimlaneTransition.find_or_create_by(swimlane: dev, transition: cr)
      SwimlaneTransition.find_or_create_by(swimlane: dev, transition: done)

      SwimlaneTransition.find_or_create_by(swimlane: cr, transition: cr_done)
      SwimlaneTransition.find_or_create_by(swimlane: cr, transition: dev)
      SwimlaneTransition.find_or_create_by(swimlane: cr, transition: done)

      SwimlaneTransition.find_or_create_by(swimlane: cr_done, transition: accept)
      SwimlaneTransition.find_or_create_by(swimlane: cr_done, transition: done)

      SwimlaneTransition.find_or_create_by(swimlane: accept, transition: accept_done)
      SwimlaneTransition.find_or_create_by(swimlane: accept, transition: done)

      SwimlaneTransition.find_or_create_by(swimlane: accept_done, transition: deploy)
      SwimlaneTransition.find_or_create_by(swimlane: accept_done, transition: done)

      SwimlaneTransition.find_or_create_by(swimlane: deploy, transition: done)
    end

    Repo.all.each do |repo|
      puts "Processing repo #{repo.name}"
      board = repo.boards.first

      @lanes = {}
      board.swimlanes.each do |swimlane| 
        @lanes["status: #{swimlane.name.downcase}"] = swimlane.id
      end

      Octokit.issues(repo.remote_url).each do |issue|
        puts "  issue #{issue.number}"
        ticket = Ticket.find_or_initialize_by(remote_id: issue.id)
        ticket.state = 'Backlog' unless ticket.persisted?
        ticket.update_attributes(
          remote_number: issue.number,
          remote_title: issue.title,
          remote_body: issue.body,
          remote_state: issue.state,
          repo_id: repo.id
        )

        status = issue.labels.select { |label| label.name.start_with? 'status:' }
        board_ticket = BoardTicket.find_or_create_by(ticket: ticket, board: board)
        if status.count == 1
          swimlane = @lanes[status.first.name]
        else
          swimlane = @lanes['status: backlog']
        end

      end

      Repo.all.each do |repo|
        puts "Processing repo #{repo.name}"
        board = repo.boards.first

        @lanes = {}
        board.swimlanes.each do |swimlane| 
          @lanes["status: #{swimlane.name.downcase}"] = swimlane.id
        end

        Octokit.issues(repo.remote_url).each do |issue|
          puts "  issue #{issue.number}"
          ticket = Ticket.find_or_initialize_by(remote_id: issue.id)
          ticket.update_attributes(
            remote_number: issue.number,
            remote_title: issue.title,
            remote_body: issue.body,
            remote_state: issue.state,
            repo_id: repo.id
          )

          status = issue.labels.select { |label| label.name.start_with? 'status:' }
          board_ticket = BoardTicket.find_or_create_by(ticket: ticket, board: board)
          if status.count == 1
            swimlane = @lanes[status.first.name]
          else
            swimlane = @lanes['status: backlog']
          end
          board_ticket.update_attributes(swimlane_id: swimlane)

          Octokit.issue_comments(repo.remote_url, issue.number).each do |issue_comment|
            comment = Comment.find_or_initialize_by(remote_id: issue_comment.id)
            comment.update_attributes(
              ticket_id: ticket.id,
              remote_body: issue_comment.body,
              remote_author_id: issue_comment.user.id,
              remote_author: issue_comment.user.login
            )
          end
        end
      end
    end
  end
end
