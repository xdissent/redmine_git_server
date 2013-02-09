class Repository::GitServer < Repository::Git

  validates_uniqueness_of :url
  validate :url_format_inclusion
  validate :url_format_check, on: :create

  before_validation(on: :create) do
    self.extra_info ||= {}
    extra_info["extra_url_format"] ||= self.class.default_url_format
  end

  def self.scm_adapter_class
    RedmineGitServer::GitoliteAdapter
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