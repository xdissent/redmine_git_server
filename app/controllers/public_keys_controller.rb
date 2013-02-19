class PublicKeysController < ApplicationController
  before_filter :require_login

  before_filter :find_user
  before_filter :find_public_key, :authorize_owner, only: [:show, :destroy]

  # GET /public_keys
  # GET /public_keys.json
  def index
    @public_keys = PublicKey.where user_id: @user

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @public_keys }
    end
  end

  # GET /public_keys/1
  # GET /public_keys/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @public_key }
    end
  end

  # GET /public_keys/new
  # GET /public_keys/new.json
  def new
    @public_key = PublicKey.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @public_key }
    end
  end

  # POST /public_keys
  # POST /public_keys.json
  def create
    @public_key = PublicKey.new(params[:public_key])
    @public_key.user = @user

    respond_to do |format|
      if @public_key.save
        GitWit.add_authorized_key(@user.login, @public_key.raw_content)

        format.html { redirect_to @public_key, notice: 'PublicKey was successfully created.' }
        format.json { render json: @public_key, status: :created, location: @public_key }
      else
        format.html { render action: "new" }
        format.json { render json: @public_key.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /public_keys/1
  # DELETE /public_keys/1.json
  def destroy
    @public_key.destroy 
    GitWit.remove_authorized_key(@public_key.raw_content)

    respond_to do |format|
      format.html { redirect_to public_keys_url }
      format.json { head :no_content }
    end
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
