class Repository::GitServer < Repository::Git

  validates_uniqueness_of :url
  validate :url_format_inclusion
  validate :url_format_check, on: :create

  before_validation(on: :create) do
    self.extra_info ||= {}
    extra_info["extra_url_format"] ||= self.class.default_url_format
  end

  after_create :create_git_repository, unless: :git_repository_exists?

  def create_git_repository
    Grit::Repo.init_bare git_repository_path
    install_git_hooks
  end

  def destroy_git_repository
    FileUtils.rm_rf git_repository_path
  end

  def git_repository_path
    File.join GitWit.repositories_path, url
  end

  def git_repository_exists?
    File.exists? git_repository_path
  end

  def git_hooks_path
    File.join git_repository_path, "hooks"
  end

  def post_receive_hook_path
    File.join git_hooks_path, "post-receive"
  end

  def install_git_hooks
    File.open(post_receive_hook_path, "w") { |f| f.write post_receive_hook }
    File.chmod 0700, post_receive_hook_path
  end

  def post_receive_hook
    http = Setting.protocol
    host = Setting.host_name
    key = Setting.sys_api_key
    hook_url = "#{http}://#{host}/sys/fetch_changesets?key=#{key}"
    hook_url << "&id=#{project.id}" if project.present?
    %(#!/bin/sh\ncurl "#{hook_url}")
  end

  def self.scm_adapter_class
    RedmineGitServer::GitWitAdapter
  end

  def self.scm_name
    "Git (hosted)"
  end

  def self.url_formats
    %w{hierarchical flat custom}
  end

  def self.default_url_format
    Setting.plugin_redmine_git_server["default_url_format"]
  end

  def report_last_commit
    true
  end

  def extra_report_last_commit
    true
  end

  def extra_url_format
    extra_info.present? && extra_info["extra_url_format"] || self.class.default_url_format
  end
  alias_method :url_format, :extra_url_format

  def extra_url_format=(format)
    merge_extra_info "extra_url_format" => format
  end
  alias_method :url_format=, :extra_url_format=

  def calculate_url
    return url if url_format == "custom"
    return "#{identifier}.git" unless project.present?
    ph = project.self_and_ancestors.map(&:identifier)
    (url_format == "flat" ? ph.last : ph.join("/")) + (identifier.present? ? "/#{identifier}.git" : ".git")
  end

private

  def persistent_extra_info
    %w{extra_url_format}
  end

  def clear_extra_info_of_changesets
    return unless extra_info.present?
    h = extra_info.select { |k, v| persistent_extra_info.include? k }
    write_attribute(:extra_info, nil)
    merge_extra_info(h)
    self.save
  end

  def url_format_inclusion
    if extra_info.present? && extra_info["extra_url_format"].present?
      errors.add(:extra_url_format, :inclusion) unless self.class.url_formats.include? extra_info["extra_url_format"]
    else
      errors.add(:extra_url_format, :blank)
    end
  end

  def url_format_check
    errors.add(:url, "doesn't match format") unless url == calculate_url
  end
end