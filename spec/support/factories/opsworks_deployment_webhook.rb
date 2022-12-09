FactoryBot.define do
  factory :opsworks_deployment_webhook, class: 'Hash' do
    skip_create

    app_id { SecureRandom.uuid }
    app_name { 'my-app' }
    repo_url { "git@github.com:CreatekIO/#{app_name}" }
    revision { 'master' }
    deployment_id { SecureRandom.uuid }
    duration { 30 }
    status { 'successful' }
    created_at { 1.minute.ago.utc }
    completed_at { created_at + duration.seconds }
    stack_id { SecureRandom.uuid }
    stack_name { "#{app_name}-production" }

    # Should match structure in notification lambda
    initialize_with do
      {
        app: {
          id: app_id,
          name: app_name,
          repo_url: repo_url,
          revision: revision
        },
        deployment: {
          id: deployment_id,
          duration: duration,
          status: status,
          created_at: created_at,
          completed_at: completed_at
        },
        stack: {
          id: stack_id,
          name: stack_name
        }
      }
    end
  end
end
