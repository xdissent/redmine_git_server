class PostReceiveHooksController < ApplicationController
  
  before_filter :check_api_enabled, only: :run
  before_filter :find_repository, only: [:run, :index, :create, :new]
  before_filter :find_post_receive_hook, only: [:show, :edit, :update, :destroy]
  before_filter :check_project

  skip_before_filter :verify_authenticity_token, :check_if_login_required, 
    only: :run

  def run
    @repository.fetch_changesets
    deliver_payloads if @repository.post_receive_hooks.any?
    render text: "Thanks for using Redmine Git Server\n", status: 200
  end

  def index
    @post_receive_hooks = @repository.post_receive_hooks

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @post_receive_hooks }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @post_receive_hook }
    end
  end

  def new
    @post_receive_hook = PostReceiveHook.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @post_receive_hook }
    end
  end

  def edit
  end

  def create
    @post_receive_hook = PostReceiveHook.new(params[:post_receive_hook])
    @post_receive_hook.repository = @repository

    respond_to do |format|
      if @post_receive_hook.save
        format.html { redirect_to @post_receive_hook, notice: 'Post receive hook was successfully created.' }
        format.json { render json: @post_receive_hook, status: :created, location: @post_receive_hook }
      else
        format.html { render action: "new" }
        format.json { render json: @post_receive_hook.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @post_receive_hook.update_attributes(params[:post_receive_hook])
        format.html { redirect_to @post_receive_hook, notice: 'Post receive hook was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @post_receive_hook.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @post_receive_hook.destroy

    respond_to do |format|
      format.html { redirect_to post_receive_hooks_url }
      format.json { head :no_content }
    end
  end

  private
  def check_api_enabled
    User.current = nil
    unless Setting.sys_api_enabled? && params[:key].to_s == Setting.sys_api_key
      msg = "Access denied. Repository management WS is disabled or key is invalid."
      render text: msg, status: 403
    end
  end

  def find_repository
    @repository = Repository::GitServer.find params[:repository_id]
  rescue ActiveRecord::RecordNotFound
    render_404_or_api
  end

  def check_project
    p = @repository.project
    unless p.present? && p.active? && p.module_enabled?(:repository)
      render_404_or_api
    end
  end

  def deliver_payloads
    payloads = PostReceiveHook::Payload.parse_refs @repository, request.body.read
    @repository.post_receive_hooks.find_each { |p| p.deliver_payloads payloads }
  end

  def render_404_or_api
    if params[:action] == "run"
      render nothing: true, status: 404
    else
      render_404
    end
  end

  def find_post_receive_hook
    @post_receive_hook = PostReceiveHook.find(params[:id])
    @repository = @post_receive_hook.repository
    render_404 unless @repository.present? && @repository.is_a?(Repository::GitServer)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
