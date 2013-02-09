require "active_support/configurable"

module RedmineGitServer
  include ActiveSupport::Configurable

  def self.config
    return @_config if @_config.present?
    config_defaults(super)
  end

private

  def self.config_defaults(c)
    rc = redmine_conf

    c.user = rc.user || "git"

    default_home = File.expand_path("~#{c.user}") rescue "/var/git"
    c.home = rc.home || default_home

    gitolite_src = File.join(c.home, "gitolite-source/src")
    c.gitolite = rc.gitolite || File.join(gitolite_src, "gitolite")
    c.gitolite_shell = rc.gitolite_shell || File.join(gitolite_src, "gitolite-shell")

    c.repositories = rc.repositories || File.join(c.home, "repositories")

    c.anonymous_user = rc.anonymous_user || "anonymous"

    c.realm = rc.realm || "Redmine Git Server"
    c
  end

  def self.redmine_conf
    return @redmine_conf if @redmine_conf.present?
    @redmine_conf = ActiveSupport::OrderedOptions.new
    %w{user home gitolite gitolite_shell repositories anonymous_user realm}.each do |k|
      @redmine_conf[k.to_sym] = Redmine::Configuration["scm_git_server_#{k}"]
    end
    @redmine_conf
  end
end