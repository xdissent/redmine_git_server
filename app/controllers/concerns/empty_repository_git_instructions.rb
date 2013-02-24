module EmptyRepositoryGitInstructions
  extend ActiveSupport::Concern

  included do
    super_show_error_not_found = instance_method :show_error_not_found
    define_method :show_error_not_found do
      unless params[:controller] == "repositories" && params[:action] == "show" && \
        @repository.present? && @repository.is_a?(Repository::GitServer) && \
        User.current.allowed_to?(:commit_access, @project)
        return super_show_error_not_found.bind(self).call
      end
      @repositories = @project.repositories.presence || []
      render "repositories/empty"
    end
  end
end