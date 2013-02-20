module RedmineGitServer
  module Hooks
    class ProjectShowHook < Redmine::Hook::ViewListener
      render_on :view_projects_show_right, partial: "projects/git_urls"
    end

    class RepositoryShowHook < Redmine::Hook::ViewListener
      render_on :view_repositories_show_contextual, partial: "repositories/git_urls"
    end

    class MyAccountHook < Redmine::Hook::ViewListener
      render_on :view_my_account_contextual, partial: "my/public_keys_link"
    end

    class SidebarHook < Redmine::Hook::ViewListener
      render_on :view_layouts_base_sidebar, partial: "post_receive_hooks/sidebar"
    end
  end
end