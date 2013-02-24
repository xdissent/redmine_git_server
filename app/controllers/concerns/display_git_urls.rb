module DisplayGitUrls
  extend ActiveSupport::Concern

  included do
    private
    def show_error_not_found
      unless params[:controller] == "repositories" && params[:action] == "show" && \
        @repository.present? && @repository.is_a?(Repository::GitServer) && \
        User.current.allowed_to?(:commit_access, @project)
        return super
      end
      @repositories = [] unless @repositories.present?
      render "repositories/empty"
    end
  end
end