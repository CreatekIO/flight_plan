require 'rails_helper'

RSpec.describe 'touching', type: :model do
  let(:time_in_past) { 2.days.ago }

  def create_in_the_past(factory, *args, **attributes)
    ActiveRecord::Base.no_touching do
      create(factory, *args, **attributes, created_at: time_in_past, updated_at: time_in_past)
    end
  end

  let!(:touches) { [] }

  before do
    # allow(ActiveRecord::Associations::Builder::BelongsTo).to receive(:touch_record).and_wrap_original do |m, *args|
    #   touches << args
    #   m.call(*args)
    # end
    allow_any_instance_of(ActiveRecord::Base).to receive(:touch_later).and_wrap_original do |m, *args|
      # touches << "#{m.receiver.class}/#{m.receiver.id}"
      touches << m.receiver
      m.call(*args)
    end

    allow_any_instance_of(ActiveRecord::Base).to receive(:inspect) do |receiver|
      "<#{receiver.class}/#{receiver.id}>"
    end
  end

  let(:board) { create_in_the_past(:board) }
  let(:repo) { create_in_the_past(:repo) }
  let(:board_repo) { create_in_the_past(:board_repo, board: board, repo: repo) }
  let(:current_swimlane) { create_in_the_past(:swimlane, board: board, position: 1) }
  let(:new_swimlane) { create_in_the_past(:swimlane, board: board, position: 2) }
  let(:board_ticket) { create_in_the_past(:board_ticket, ticket: ticket, swimlane: swimlane, board: board) }
  let(:ticket) { create_in_the_past(:ticket, repo: repo, remote_body: 'test') }
  let(:other_ticket) { create_in_the_past(:ticket, repo: repo, remote_body: 'test') }
  let(:comment) { create_in_the_past(:comment, ticket: ticket) }
  let(:pull_request) { create_in_the_past(:pull_request, repo: repo) }

  alias_method :swimlane, :current_swimlane
  alias_method :load_let, :send

  before do
    allow(board_ticket).to receive(:update_github)
  end

  def timestamps_of(*records)
    records.each_with_object({}) do |record, timestamps|
      timestamps["#{record.class}/#{record.id}"] = record.reload.updated_at.iso8601
    end
  end

  def have_touched(*records)
    originals = touches.count
    records = records.first unless records.first.is_a?(ActiveRecord::Base)

    change {
      touches.drop(originals).uniq
    }.from([]).to(records)
  end

  describe 'reordering swimlane' do
    before { load_let(:swimlane) }

    it 'touches board' do
      expect {
        swimlane.update_attributes!(position: swimlane.position + 1)
      }.to have_touched(board)
    end
  end

  describe 'moving board ticket between swimlanes' do
    before { load_let(:board_ticket) }

    it 'touches all parents' do
      expect {
        board_ticket.update_attributes!(swimlane: new_swimlane)
      }.to have_touched a_collection_including(board, current_swimlane, new_swimlane)
    end
  end

  describe 'adding a ticket' do
    before do
      load_let(:swimlane)
      load_let(:board_repo)
    end

    it 'touches swimlane and board' do
      expect {
        Ticket.import({ id: 1_000, labels: [] }, full_name: repo.remote_url)
      }.to have_touched(board, swimlane)
    end
  end

  describe 'updating ticket' do
    before { load_let(:ticket) }

    it 'touches all parents' do
      expect {
        ticket.update_attributes!(remote_body: ticket.remote_body.reverse)
      }.to change {
        timestamps_of(board, repo, swimlane, board_ticket)
      }
    end
  end

  describe 'adding comment' do
    before { load_let(:ticket) }

    it 'touches all parents' do
      expect {
        Comment.import({ id: 1_000, user: {} }, { id: ticket.remote_id }, full_name: repo.remote_url)
      }.to change {
        timestamps_of(board, repo, swimlane, board_ticket, ticket)
      }
    end
  end

  describe 'updating comment' do
    before { load_let(:comment) }

    it 'touches all parents' do
      expect {
        comment.update_attributes!(remote_body: comment.remote_body.reverse)
      }.to change {
        timestamps_of(board, repo, swimlane, board_ticket, ticket)
      }
    end
  end

  describe 'adding pull request' do
    before { load_let(:ticket) }

    it 'touches all parents' do
      expect {
        PullRequest.import(
          { id: 1_000, head: { ref: 'test' }, base: {}, user: {}, body: "Connects ##{ticket.remote_id}" },
          full_name: repo.remote_url
        )
      }.to change {
        timestamps_of(board, repo, swimlane, board_ticket, ticket)
      }
    end
  end

  describe 'updating pull request' do
    before do
      load_let(:pull_request)
      load_let(:other_ticket)
    end

    it 'touches all parents but not unrelated ticket' do
      expect {
        pull_request.update_attributes!(remote_title: pull_request.remote_title.reverse)
      }.to change {
        timestamps_of(board, repo, swimlane, board_ticket, ticket)
      }
    end

    it 'does not touch unrelated ticket' do
      expect {
        pull_request.update_attributes!(remote_title: pull_request.remote_title.reverse)
      }.not_to change {
        timestamps_of(ticket, other_ticket)
      }
    end
  end
end
