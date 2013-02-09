module GitServerRepositoriesHelper
  def git_server_field_tags(form, repository)
    render partial: "repositories/git_server_repository_fields", locals: {f: form, repo: repository}
  end

  def git_server_url_format_options
    Repository::GitServer.url_formats.map do |f| 
      [l("label_git_server_url_format_#{f}".to_sym), f]
    end
  end
end