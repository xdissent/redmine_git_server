class PostReceiveHooksController < ApplicationController
  menu_item :repository

  respond_to :html, :json
  respond_to :js, except: [:run, :index]

  skip_before_filter :verify_authenticity_token, :check_if_login_required, 
    only: :run

  before_filter :check_api_enabled, :find_repository_api, only: :run
  before_filter :find_project_and_repository, except: :run
  before_filter :authorize, except: :run
  before_filter :find_post_receive_hook, except: [:run, :index, :new, :create]
  before_filter :check_project
  before_filter :find_repositories, except: :run

  def run
    @repository.fetch_changesets
    deliver_payloads
  end

  def index
    @post_receive_hooks = @repository.post_receive_hooks
    respond_with @post_receive_hooks
  end

  def show
    respond_with @post_receive_hook
  end

  def new
    @post_receive_hook = PostReceiveHook.new
    respond_with @post_receive_hook
  end

  def edit
    respond_with @post_receive_hook
  end

  def create
    @post_receive_hook = PostReceiveHook.new(params[:post_receive_hook])
    @post_receive_hook.repository = @repository
    if @post_receive_hook.save && !request.xhr?
      flash[:notice] = "Post receive hook was successfully created."
    end
    respond_with @post_receive_hook
  end

  def update
    if @post_receive_hook.update_attributes(params[:post_receive_hook]) && !request.xhr?
      flash[:notice] = "Post receive hook was successfully updated."
    end
    respond_with @post_receive_hook
  end

  def destroy
    @post_receive_hook.destroy
    flash[:notice] = "Post receive hook was successfully deleted." unless request.xhr?
    respond_with @post_receive_hook, location: post_receive_hooks_url(@project, @repository)
  end

  def url_options
    return super if params[:action] == "run"
    super.reverse_merge project_id: @project, repository_id: @repository
  end
  

  private
  def check_api_enabled
    User.current = nil
    unless Setting.sys_api_enabled? && params[:key].to_s == Setting.sys_api_key
      msg = "Access denied. Repository management WS is disabled or key is invalid."
      render text: msg, status: 403
    end
  end

  def find_repository_api
    @repository = Repository::GitServer.find params[:repository_id]
    @project = @repository.project
  rescue ActiveRecord::RecordNotFound
    render nothing: true, status: 404
  end

  def find_project_and_repository
    @project = Project.find params[:project_id]
    scope = @project.repositories.where type: Repository::GitServer
    @repository = scope.find params[:repository_id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_post_receive_hook
    @post_receive_hook = @repository.post_receive_hooks.find params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_repositories
    @repositories = @project.repositories # Needed for repositories sidebar
  end

  def check_project
    render_404_or_api unless @project.present? && @project.active? && \
      @project.module_enabled?(:repository)
  end

  def payloads
    return [] unless hooks.any?
    PostReceiveHook::Payload.parse_refs @repository, request.body.read
  end

  def hooks
    @repository.post_receive_hooks
  end

  def deliver_payloads
    self.response_body = PostReceiveHook::PayloadStreamer.new payloads, hooks
  end

  def render_404_or_api
    if params[:action] == "run"
      render nothing: true, status: 404
    else
      render_404
    end
  end
end
