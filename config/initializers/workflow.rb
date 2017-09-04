WORKFLOW = HashWithIndifferentAccess.new(
  YAML.load_file(Rails.root.join('config/workflow.yml'))
)
