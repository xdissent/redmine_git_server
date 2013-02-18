module RedmineGitServer
  class GitWitAdapter < Redmine::Scm::Adapters::GitAdapter
    def initialize(url, root_url = nil, login = nil, password = nil, path_encoding = nil)
      full_path = File.join(GitWit.repositories_path, url)
      super full_path, root_url, login, password, path_encoding
    end
  end
end