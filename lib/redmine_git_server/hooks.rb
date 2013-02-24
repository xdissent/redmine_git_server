module RedmineGitServer
  module Hooks
    class ProjectShowHook < Redmine::Hook::ViewListener
      render_on :view_projects_show_right, partial: "projects/git_urls"
    end

    class RepositoryShowHook < Redmine::Hook::ViewListener
      render_on :view_repositories_show_contextual, partial: "repositories/git_urls"
    end

    class PostReceiveHookSidebarHook < Redmine::Hook::ViewListener
      render_on :view_layouts_base_sidebar, partial: "post_receive_hooks/sidebar"
    end

    class PublicKeysSidebarHook < Redmine::Hook::ViewListener
      render_on :view_layouts_base_sidebar, partial: "public_keys/sidebar"
    end
  end
end