FactoryBot.define do
  factory :board do
    transient do
      repo_slugs { [] }
      swimlane_names { [] }
    end

    name { 'My Board' }
    slack_channel { '#general' }

    after(:create) do |board, evaluator|
      evaluator.repo_slugs.each do |slug|
        board.repos << Repo.find_by(slug: slug) || create(:repo, slug: slug)
      end

      evaluator.swimlane_names.each.with_index(1) do |name, index|
        swimlane = create(:swimlane, name: name, board: board, position: index)
        next unless index == (evaluator.swimlane_names.size - 1)

        board.update!(deploy_swimlane: swimlane)
      end
    end
  end
end
