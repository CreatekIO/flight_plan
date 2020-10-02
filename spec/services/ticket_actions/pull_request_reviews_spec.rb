require 'rails_helper'

RSpec.describe TicketActions::PullRequestReviews, type: :ticket_action do
  subject { described_class.new(pull_request) }

  describe '#next_action' do
    let(:repo) { create(:repo) }
    let(:creator) { build_stubbed(:user) }
    let(:review_user) { build_stubbed(:user) }

    let(:pull_request) do
      build_stubbed(
        :pull_request,
        repo: repo,
        creator_remote_id: creator.uid,
        creator_username: creator.name.parameterize.underscore
      )
    end

    let(:pr_url) { pull_request.html_url }

    def add_review(state, reviewer: review_user, **attrs)
      @review_count ||= 0
      @review_count += 1

      time = (30 - @review_count).minutes.ago

      create(
        :pull_request_review,
        repo: repo,
        state: state,
        pull_request: pull_request,
        sha: pull_request.head_sha,
        reviewer_remote_id: reviewer.uid,
        reviewer_username: reviewer.name.parameterize.underscore,
        remote_created_at: time,
        created_at: time,
        **attrs
      )
    end

    context 'with no reviews' do
      before do
        pull_request.reviews.map(&:destroy!)
      end

      it 'tells user to add a review' do
        expect(subject.next_action).to be_a_positive_action('Add a review', urls: "#{pr_url}/files")
      end
    end

    context 'with changes requested' do
      let(:reviewers) { build_stubbed_list(:user, reviewer_count) }

      before do
        reviewers.each do |reviewer|
          add_review(:changes_requested, reviewer: reviewer)
        end
      end

      context 'by one user' do
        let(:reviewer_count) { 1 }

        it 'tells user to address changes' do
          expect(subject.next_action).to be_a_warning_action('Address changes', urls: pr_url, user_ids: creator.uid)
        end

        context 'followed by a push on the PR branch' do
          before do
            # Mimic push to PR branch
            new_sha = generate(:sha)
            pull_request.head_sha = new_sha
          end

          it 'tells user to re-review PR' do
            expect(subject.next_action).to be_a_warning_action('Re-review updates', urls: pr_url)
          end

          context 'and reviewer re-reviews' do
            let(:reviewer) { reviewers.first }

            context 'requesting changes' do
              before do
                add_review(:changes_requested, reviewer: reviewer)
              end

              it 'tells user to address changes' do
                expect(subject.next_action).to be_a_warning_action('Address changes', urls: pr_url, user_ids: creator.uid)
              end
            end

            context 'approving changes' do
              before do
                add_review(:approved, reviewer: reviewer)
              end

              it 'returns nil' do
                expect(subject.next_action).to be_nil
              end
            end
          end

          context 'and another reviewer requests changes on latest commit' do
            let(:another_reviewer) { build_stubbed(:user) }

            before do
              add_review(:changes_requested, reviewer: another_reviewer)
            end

            it 'tells user to re-review PR' do
              expect(subject.next_action).to be_a_warning_action(
                'Re-review updates',
                urls: pr_url,
                user_ids: another_reviewer.uid
              )
            end
          end
        end
      end

      context 'by many users' do
        let(:reviewer_count) { 2 }

        it 'tells user to address changes' do
          expect(subject.next_action).to be_a_warning_action('Address changes', urls: pr_url, user_ids: creator.uid)
        end
      end
    end

    context 'with approval' do
      before do
        add_review(:approved)
      end

      it 'returns nil' do
        expect(subject.next_action).to be_nil
      end

      context 'superceded by changes requested' do
        before do
          add_review(:changes_requested)
        end

        it 'tells user to address changes' do
          expect(subject.next_action).to be_a_warning_action('Address changes', urls: pr_url, user_ids: creator.uid)
        end
      end
    end

    context 'with comments' do
      before do
        add_review(:commented)
      end

      it 'returns nil' do
        expect(subject.next_action).to be_nil
      end
    end

    context 'with review by PR creator' do
      before do
        add_review(review_state, reviewer: creator)
      end

      context 'and review approves PR' do
        let(:review_state) { :approved }

        it 'ignores review and tells user to add a review' do
          expect(subject.next_action).to be_a_positive_action('Add a review', urls: "#{pr_url}/files")
        end
      end

      context 'and review requests changes' do
        let(:review_state) { :changes_requested }

        it 'tells user to address changes' do
          expect(subject.next_action).to be_a_warning_action('Address changes', urls: pr_url, user_ids: creator.uid)
        end
      end
    end
  end
end
