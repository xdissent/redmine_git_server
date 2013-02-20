class PublicKeysController < ApplicationController

  respond_to :html, :json
  respond_to :js, except: :index

  before_filter :require_login

  before_filter :find_user
  before_filter :find_public_key, :authorize_owner, only: [:show, :destroy]

  def index
    @public_keys = PublicKey.where user_id: @user
    respond_with @public_keys
  end

  def show
    respond_with @public_key
  end

  def new
    @public_key = PublicKey.new
    respond_with @public_key
  end

  def create
    @public_key = PublicKey.new(params[:public_key])
    @public_key.user = @user

    if @public_key.save
      GitWit.add_authorized_key(@user.login, @public_key.raw_content)
      flash[:notice] = "Public key was successfully created." unless request.xhr?
    end
    respond_with @public_key
  end

  def destroy
    @public_key.destroy 
    GitWit.remove_authorized_key(@public_key.raw_content)
    flash[:notice] = "Public key was successfully deleted." unless request.xhr?
    respond_with @public_key
  end

  def find_user
    @user = User.current
  end

  def find_public_key
    @public_key = PublicKey.find params[:id]
  end

  def authorize_owner
    render_403 unless @public_key.user == @user
  end
end
