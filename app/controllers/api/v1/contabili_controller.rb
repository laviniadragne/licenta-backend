class Api::V1::ContabiliController < Api::V1::ApiController
  before_action :set_user, only: %i[ show update destroy ]
  before_action :authorize_user
  protect_from_forgery with: :null_session,
    if: Proc.new { |c| c.request.format =~ %r{application/json} }

  api :GET, '/contabili', 'Admin role: Listare contabili din aplicatie'
  def index
    # Logare acces
    Rails.logger.info "User #{current_user.id} accessed 'index' at #{Time.now}"

    @users = User.where(role: ['contabil_sef', 'contabil'])
    
    # Logare răspuns
    Rails.logger.info "User #{current_user.id} received response 200 OK at #{Time.now} for 'index'"
  end

  api :GET, '/contabili/:id', 'Admin role: Detalii pentru 1 contabil'
  param :id, :number, required: true, desc: 'id of the requested contabil'
  def show
    # Logare acces
    Rails.logger.info "User #{current_user.id} accessed 'show' at #{Time.now} for user_id #{params[:id]}"
  end

  api :POST, '/contabili', 'Admin role: Adaugare contabil'
  param :user, Hash, :required => true do
    param :name, String, 'Name of a :resource', required: true
    param :email, String, 'Email', required: true
    param :password, String, 'Password', required: true
    param :role, ['contabil_sef', 'contabil'], 'Role', required: true
  end
  def create
    # Logare acces
    Rails.logger.info "User #{current_user.id} accessed 'create' at #{Time.now} to create a user with role #{params[:user][:role]}"

    @user = User.new(user_params)

    if @user.save
      # Logare succes
      Rails.logger.info "User #{current_user.id} successfully created user with id #{@user.id} at #{Time.now}"

      render :show, status: :created
    else
      # Logare eroare
      Rails.logger.info "User #{current_user.id} failed to create user with role #{params[:user][:role]} at #{Time.now}. Errors: #{@user.errors.full_messages}"

      render json: @user.errors, status: :unprocessable_entity
    end
  end

  api :PUT, '/contabili/:id', 'Admin role: Modificare contabil'
  param :user, Hash, :required => true do
    param :name, String, 'Name of a :resource', required: true
    param :email, String, 'Email', required: true
    param :role, ['contabil_sef', 'contabil'], 'Role', required: true
  end
  def update
    # Logare acces
    Rails.logger.info "User #{current_user.id} accessed 'update' at #{Time.now} for user_id #{params[:id]}"

    if @user.update(user_params)
      # Logare succes
      Rails.logger.info "User #{current_user.id} successfully updated user with id #{@user.id} at #{Time.now}"

      render :show, status: :ok
    else
      # Logare eroare
      Rails.logger.info "User #{current_user.id} failed to update user with id #{@user.id} at #{Time.now}. Errors: #{@user.errors.full_messages}"

      render json: @user.errors, status: :unprocessable_entity
    end
  end

  api :DELETE, '/contabili/:id', 'Admin role: Sterge un contabil'
  def destroy
    # Logare acces
    Rails.logger.info "User #{current_user.id} accessed 'destroy' at #{Time.now} for user_id #{params[:id]}"

    @user.destroy

    # Logare succes
    Rails.logger.info "User #{current_user.id} successfully deleted user with id #{@user.id} at #{Time.now}"

    head :no_content
  end

  private

  def authorize_user
    head 403 unless current_user.admin?
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:name, :email, :password, :role)
  end
end
