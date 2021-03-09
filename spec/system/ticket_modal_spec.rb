require 'rails_helper'

RSpec.describe 'Ticket modal', js: true do
  let(:board) { create(:board, repos: [repo]) }
  let(:repo) { create(:repo) }
  let(:swimlane) { create(:swimlane, board: board) }

  let(:labels) { create_pair(:label, repo: repo) }
  let(:milestone) { create(:milestone, repo: repo) }

  let(:pull_requests) do
    %w[open closed].map do |state|
      create(:pull_request, state: state, repo: repo)
    end
  end

  let!(:assignments) { create_pair(:ticket_assignment, ticket: ticket) }

  let!(:ticket) do
    create(
      :ticket,
      body: <<~TEXT,
        # Heading

        - first item
        - second item

        paragraph text

        - [ ] unfinished task
        - [x] finished task
      TEXT
      creator_username: 'createkio',
      repo: repo,
      labels: labels,
      milestone: milestone,
      pull_requests: pull_requests
    )
  end

  let!(:comment) do
    create(:comment, ticket: ticket, body: <<~TEXT)
      some text in a paragraph

      - [ ] task list item
    TEXT
  end

  let!(:board_ticket) do
    create(:board_ticket, board: board, ticket: ticket, swimlane: swimlane)
  end

  before do
    Flipper.enable(:v2_ui)
    sign_in create(:user)
  end

  def assert_modal_content
    within("[data-reach-dialog-content]") do
      expect(page).to have_text(ticket.title)
      expect(page).to have_link(ticket.html_url)

      expect(page).to have_text("#{ticket.creator_username} opened issue")

      # Check ticket body markdown rendering
      expect(page).to have_css('h1', text: 'Heading')
      expect(page).to have_css('ul li', text: 'first item')
      expect(page).to have_css('ul li', text: 'second item')
      expect(page).to have_css('p', text: 'paragraph text')
      expect(page).to have_xpath(
        './/li[contains(text(), "unfinished task")]/input[@type="checkbox" and not(@checked)]'
      )
      expect(page).to have_xpath(
        './/li[contains(text(), "finished task")]/input[@type="checkbox" and @checked]'
      )

      # Check comment
      expect(page).to have_text("#{comment.author_username} commented")
      expect(page).to have_css('p', text: 'some text in a paragraph')
      expect(page).to have_xpath(
        './/li[contains(text(), "task list item")]/input[@type="checkbox" and not(@checked)]'
      )

      # Sidebar
      within('.sticky') do
        expect(page).to have_text(/\bopen\b/i)
        expect(page).to have_text(repo.name)

        labels.map(&:name).each do |label_name|
          expect(page).to have_text(label_name)
        end

        expect(page).to have_text(milestone.title)

        assignments.map(&:assignee_username).each do |username|
          expect(page).to have_link(username, href: "https://github.com/#{username}")
        end

        pull_requests.each do |pull_request|
          expect(page).to have_link(
            pull_request.number,
            href: "https://github.com/#{pull_request.repo.slug}/pull/#{pull_request.number}"
          )
        end
      end
    end
  end

  it 'allows user to open ticket modal from link' do
    visit board_path(board)

    click_on ticket.title

    assert_modal_content
  end

  it 'allows user to open ticket modal from URL' do
    visit client_side_board_path(board, "#{repo.slug}/#{ticket.number}")

    assert_modal_content
  end
end
