module GitServerRepositoriesHelper
  def git_server_field_tags(form, repository)
    render partial: "repositories/git_server_repository_fields", locals: {f: form, repo: repository}
  end

  def git_server_url_format_options
    Repository::GitServer.url_formats.map do |f| 
      [l("label_git_server_url_format_#{f}".to_sym), f]
    end
  end

  def zero_clipboard_init
    return if @zero_clipboard_initted
    @zero_clipboard_initted = true
    swf_url = "/plugin_assets/redmine_git_server/javascripts/ZeroClipboard.swf"
    content_for :header_tags do
      javascript_include_tag("ZeroClipboard.min.js", plugin: :redmine_git_server) +
      javascript_tag("ZeroClipboard.setDefaults({moviePath: '#{swf_url}'});")
    end
  end

  def git_urls_assets
    return if @git_urls_assets_loaded
    @git_urls_assets_loaded = true
    zero_clipboard_init
    content_for :header_tags do
      javascript_include_tag("git_urls", plugin: :redmine_git_server) + 
      stylesheet_link_tag("git_urls", plugin: :redmine_git_server)
    end
  end
end