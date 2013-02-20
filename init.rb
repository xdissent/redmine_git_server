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
    "default_url_format" => "hierarchical"
  }

  project_module :repository do
    permission :view_post_receive_hooks, {post_receive_hooks: [:index, :show]}, require: :member
    permission :manage_post_receive_hooks, {post_receive_hooks: [:new, :create, :edit, :update, :destroy]}, require: :member
  end

  # Autoload concerns - not necessary in Rails 4
  ActiveSupport::Dependencies.autoload_paths += %w{models controllers}.map { |c| File.join directory, "app/#{c}/concerns" }

  # Add GitServer SCM (really, registers Repository::GitServer)
  Redmine::Scm::Base.add "GitServer"

  # Add helper to controllers that need it
  RedmineApp::Application.config.to_prepare do
    RepositoriesController.send :include, GitServerRepositoriesHelped
    SettingsController.send :include, GitServerRepositoriesHelped
    ProjectsController.send :include, GitServerRepositoriesHelped
    User.send :include, HasManyPublicKeys
  end

  # Configure GitWit
  GitWit.default_config!
  GitWit.configure do |config|
    # Pull settings from configuration.yml
    settings = Redmine::Configuration["git_wit"] || {}
    %w(repositories_path ssh_user insecure_write insecure_auth 
      realm git_http_backend_path).each do |k|
      config.send "#{k}=".to_sym, settings[k] if settings[k].present?
    end

    # Active users are valid for authentication. Don't use User.anonymous for
    # anonymous users here. Use nil.
    config.user_for_authentication = ->(username) do
      User.active.find_by_login username
    end

    # Check a user record (or nil) against a password.
    config.authenticate = ->(user, password) do
      user.try :check_password?, password
    end

    # Attempt read authorization for a repository. The user will be nil if it's
    # for anonymous access, so check permissions for User.anonymous. Checks for
    # :view_changesets permission.
    config.authorize_read = ->(user, repository) do
      user ||= User.anonymous
      repo = Repository::GitServer.find_by_url repository
      return false unless repo.present? && repo.project.present?
      user.allowed_to? :view_changesets, repo.project
    end

    # Attempt write authorization for a repository. The user will be nil if it's
    # for anonymous access, so check permissions for User.anonymous. Checks for
    # :commit_access permission.
    config.authorize_write = ->(user, repository) do
      user ||= User.anonymous
      repo = Repository::GitServer.find_by_url repository
      return false unless repo.present? && repo.project.present?
      user.allowed_to? :commit_access, repo.project
    end
  end
end