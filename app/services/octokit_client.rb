module OctokitClient
  extend ActiveSupport::Concern

  module ClassMethods
    def octokit_methods(*names, prefix_with: nil)
      prefix_args = Array.wrap(prefix_with).map(&:to_s).join(', ')

      names.each do |name|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{name}(*args)
            octokit.#{name}(
              #{prefix_args + ',' if prefix_args.present?}
              *args
            )
          end
        RUBY
      end
    end
  end

  def octokit
    @octokit ||= Octokit::Client.new
  end

  def octokit_token=(new_token)
    octokit.access_token = new_token
  end
end
