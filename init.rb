require "redmine_git_server"

Redmine::Plugin.register :redmine_git_server do
  name "Redmine Git Server Plugin"
  author "Greg Thornton"
  description "Git server for Redmine using GitWit."
  version "0.0.1"
  url "http://xdissent.com"
  author_url "http://xdissent.com"
  requires_redmine version_or_higher: "2.2.3"
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

  # Configure GitWit for your application using this initializer.
  GitWit.configure do |config|
    config.repositories_path = Rails.root.join("tmp", "repositories").to_s
    config.ssh_user = "gitwit"
    config.insecure_write = true
    config.insecure_auth = true

    config.user_for_authentication = ->(username) do
      User.active.find_by_login username
    end

    config.authenticate = ->(user, password) do
      user.try :check_password?, password
    end

    config.authorize_read = ->(user, repository) do
      user ||= User.anonymous
      repo = Repository::GitServer.find_by_url repository
      return false unless repo.present? && repo.project.present?
      user.allowed_to? :view_changesets, repo.project
    end

    config.authorize_write = ->(user, repository) do
      user ||= User.anonymous
      repo = Repository::GitServer.find_by_url repository
      return false unless repo.present? && repo.project.present?
      user.allowed_to? :commit_access, repo.project
    end
  end
end