namespace :github do
  task :pull => :environment do
    d = Repo.find_or_create_by(name: 'Dummy', remote_url: 'jcleary/dummy')
    fp = Repo.find_or_create_by(name: 'FlightPlan', remote_url: 'CreatekIO/flight_plan')
    myr = Repo.find_or_create_by(name: 'MyRewards', remote_url: 'CorporateRewards/myrewards')
    gps = Repo.find_or_create_by(name: 'GPS', remote_url: 'CorporateRewards/redstone')

    fp_board = Board.find_or_create_by(name: 'Flight Plan') do |board|
      board.repos << fp
      board.save
    end

    d_board = Board.find_or_create_by(name: 'Dummy') do |board|
      board.repos << d
      board.save
    end

    cr_board = Board.find_or_create_by(name: 'Corporate Rewards') do |board|
      board.repos << myr
      board.repos << gps
      board.save
    end

    [fp_board, cr_board, d_board].each do |board|
      position = 0
      backlog = Swimlane.find_or_create_by(board: board, name: 'Backlog').tap{ |s|s.update_attributes(position: position+=1) }
      bugs = Swimlane.find_or_create_by(board: board, name: 'Backlog - Bugs').tap{ |s|s.update_attributes(position: position+=1) }
      plan = Swimlane.find_or_create_by(board: board, name: 'Planning').tap{ |s|s.update_attributes(position: position+=1) }
      plan_done = Swimlane.find_or_create_by(board: board, name: 'Planning - DONE').tap{ |s|s.update_attributes(position: position+=1) }
      dev = Swimlane.find_or_create_by(board: board, name: 'Development', display_duration: true).tap{ |s|s.update_attributes(position: position+=1) }
      blocked = Swimlane.find_or_create_by(board: board, name: 'Development - blocked', display_duration: true).tap{ |s|s.update_attributes(position: position+=1) }
      cr = Swimlane.find_or_create_by(board: board, name: 'Code Review', display_duration: true).tap{ |s|s.update_attributes(position: position+=1) }
      cr_done = Swimlane.find_or_create_by(board: board, name: 'Code Review - DONE', display_duration: true).tap{ |s|s.update_attributes(position: position+=1) }
      accept = Swimlane.find_or_create_by(board: board, name: 'Acceptance', display_duration: true).tap{ |s|s.update_attributes(position: position+=1) }
      accept_done = Swimlane.find_or_create_by(board: board, name: 'Acceptance - DONE', display_duration: true).tap{ |s|s.update_attributes(position: position+=1) }
      deploy = Swimlane.find_or_create_by(board: board, name: 'Deploying', display_duration: true).tap{ |s|s.update_attributes(position: position+=1) }
      done = Swimlane.find_or_create_by(board: board, name: 'Deploying - DONE').tap{ |s|s.update_attributes(position: position+=1) }

      SwimlaneTransition.find_or_create_by(swimlane: backlog, transition: plan).update(position: 1)
      SwimlaneTransition.find_or_create_by(swimlane: backlog, transition: bugs).update(position: 2)
      SwimlaneTransition.find_or_create_by(swimlane: backlog, transition: plan_done).update(position: 3)
      SwimlaneTransition.find_or_create_by(swimlane: backlog, transition: dev).update(position: 4)
      SwimlaneTransition.find_or_create_by(swimlane: backlog, transition: done).update(position: 5)

      SwimlaneTransition.find_or_create_by(swimlane: bugs, transition: dev).update(position: 1)
      SwimlaneTransition.find_or_create_by(swimlane: bugs, transition: backlog).update(position: 2)
      SwimlaneTransition.find_or_create_by(swimlane: bugs, transition: plan).update(position: 3)
      SwimlaneTransition.find_or_create_by(swimlane: bugs, transition: plan_done).update(position: 4)
      SwimlaneTransition.find_or_create_by(swimlane: bugs, transition: done).update(position: 5)

      SwimlaneTransition.find_or_create_by(swimlane: plan, transition: plan_done).update(position: 1)
      SwimlaneTransition.find_or_create_by(swimlane: plan, transition: backlog).update(position: 2)
      SwimlaneTransition.find_or_create_by(swimlane: plan, transition: done).update(position: 3)

      SwimlaneTransition.find_or_create_by(swimlane: plan_done, transition: dev).update(position: 1)
      SwimlaneTransition.find_or_create_by(swimlane: plan_done, transition: plan).update(position: 2)
      SwimlaneTransition.find_or_create_by(swimlane: plan_done, transition: done).update(position: 3)

      SwimlaneTransition.find_or_create_by(swimlane: dev, transition: cr).update(position: 1)
      SwimlaneTransition.find_or_create_by(swimlane: dev, transition: plan_done).update(position: 2)
      SwimlaneTransition.find_or_create_by(swimlane: dev, transition: done).update(position: 3)

      SwimlaneTransition.find_or_create_by(swimlane: cr, transition: cr_done).update(position: 1)
      SwimlaneTransition.find_or_create_by(swimlane: cr, transition: dev).update(position: 2)
      SwimlaneTransition.find_or_create_by(swimlane: cr, transition: done).update(position: 3)

      SwimlaneTransition.find_or_create_by(swimlane: cr_done, transition: accept).update(position: 1)
      SwimlaneTransition.find_or_create_by(swimlane: cr_done, transition: done).update(position: 2)

      SwimlaneTransition.find_or_create_by(swimlane: accept, transition: accept_done).update(position: 1)
      SwimlaneTransition.find_or_create_by(swimlane: accept, transition: done).update(position: 2)

      SwimlaneTransition.find_or_create_by(swimlane: accept_done, transition: deploy).update(position: 1)
      SwimlaneTransition.find_or_create_by(swimlane: accept_done, transition: done).update(position: 2)

      SwimlaneTransition.find_or_create_by(swimlane: deploy, transition: done).update(position: 1)
    end

    Repo.all.each do |repo|
      puts "Processing repo #{repo.name}"

      remote_repo = { full_name: repo.remote_url }
      Octokit.issues(repo.remote_url).each do |remote_issue|
        next if remote_issue.pull_request.present?
        puts "  issue #{remote_issue.number}"
        ticket = Ticket.import(remote_issue, remote_repo)

        Octokit.issue_comments(repo.remote_url, ticket.remote_number).each do |issue_comment|
          comment = Comment.find_or_initialize_by(remote_id: issue_comment.id)
          comment.update_attributes(
            ticket_id: ticket.id,
            remote_body: issue_comment.body,
            remote_author_id: issue_comment.user.id,
            remote_author: issue_comment.user.login
          )
        end
      end

      repo.update_merged_tickets
    end
  end
end

