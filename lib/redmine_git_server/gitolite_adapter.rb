module RedmineGitServer
  class GitoliteAdapter < Redmine::Scm::Adapters::GitAdapter

    def git_cmd(args, options = {}, &block)
      raise NotImplementedError
    end
    private :git_cmd
  end
end