module GitServerRepositoriesHelped
  extend ActiveSupport::Concern

  included do
    helper :git_server_repositories
  end
end