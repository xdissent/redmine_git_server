class PostReceiveHooksController < ApplicationController
  
  before_filter :check_api_enabled, only: :run
  before_filter :find_repository, only: [:run, :index, :create, :new]
  before_filter :find_post_receive_hook, only: [:show, :edit, :update, :destroy]
  before_filter :check_project

  skip_before_filter :verify_authenticity_token, :check_if_login_required, 
    only: :run

  def run
    @repository.fetch_changesets
    deliver_payloads
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
      format.html { redirect_to post_receive_hooks_url(@post_receive_hook.repository) }
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

  def payloads
    return [] unless @repository.post_receive_hooks.any?
    PostReceiveHook::Payload.parse_refs @repository, request.body.read
  end

  def hooks
    @repository.post_receive_hooks
  end

  def deliver_payloads
    self.response_body = PayloadStreamer.new payloads, hooks
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

  class PayloadStreamer
    attr_accessor :payloads, :hooks, :failures

    def initialize(payloads, hooks)
      self.payloads = payloads
      self.hooks = hooks
      self.failures = []
    end

    def outro
      "Thanks for using Redmine Git Server\n"
    end

    def failure_boundary
      "\n*** WARNING ***\n\n"
    end

    def failures_display
      failure_boundary +
      "The following hooks had errors:\n" +
      failures.uniq.map { |f| "\t#{f.name} (#{f.url}) - errors: #{failures.count(f)}\n" }.join +
      "\nDon't panic - your code is fine.\n\n"
    end

    def each
      yield "Beginning post-receive hooks...\n" if payloads.any? && hooks.any?
      payloads.each_with_index do |payload, payload_index|
        yield "Delivering hooks payload #{payload_index + 1} of #{payloads.length}...\n"
        hooks.find_each do |hook|
          begin
            yield "\tPOSTing to hook #{hook.name} - #{hook.url}... "
            hook.deliver_payload payload
            yield "success!\n"
          rescue PostReceiveHook::HookError => error
            yield "\n\n*** Oops! The hook named #{hook.name} failed: #{error.message}\n\n"
            failures << hook
          end
        end
        yield "Delivered payload #{payload_index + 1} of #{payloads.length}\n"
      end
      yield failures_display if failures.any?
      yield outro
    end
  end
end
