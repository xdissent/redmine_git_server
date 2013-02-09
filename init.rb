require "redmine_git_server"

Redmine::Plugin.register :redmine_git_server do
  name "Redmine Git Server Plugin"
  author "Greg Thornton"
  description "Git server for Redmine using gitolite."
  version "0.0.1"
  url "http://xdissent.com"
  author_url "http://xdissent.com"
  requires_redmine version_or_higher: "2.2.2"
  settings partial: "redmine_git_server", default: {
    'default_url_format' => 'hierarchical'
  }

  # Autoload concerns - not necessary in Rails 4
  ActiveSupport::Dependencies.autoload_paths += %w{models controllers}.map { |c| File.join directory, "app/#{c}/concerns" }

  # Add GitServer SCM (really, registers Repository::GitServer)
  Redmine::Scm::Base.add "GitServer"

  # Add helper to controllers that need it
  RedmineApp::Application.config.to_prepare do
    RepositoriesController.send :include, GitServerRepositoriesHelped
    SettingsController.send :include, GitServerRepositoriesHelped
  end

  # Register git HTTP middlewhere
  RedmineApp::Application.config.middleware.use RedmineGitServer::GitHttpMiddleware
end