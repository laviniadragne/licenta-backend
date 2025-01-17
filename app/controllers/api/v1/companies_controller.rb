class Api::V1::CompaniesController < Api::V1::ApiController
  before_action :set_company, only: %i[show update destroy]
  before_action :authorize_user

  # Switch firm
  api :GET, '/companies', 'Toti utilizatorii: Afiseaza lista de companii din contul utilizatorului'
  returns code: 200, desc: "returns an Array of Hashes" do
    property :company, array_of: Hash do
      property :id, Integer, "An integer value"
      property :name, String, "A string value"
    end
  end
  def index
    @companies = current_user.visible_companies
    
    # Logare acces
    Rails.logger.info "User #{current_user.id} accessed 'index' at #{Time.now}. Visible companies count: #{@companies.count}"
  end

  api :GET, '/companies/:id', 'Toti utilizatorii: Afiseaza detalii pentru 1 companie din contul utilizatorului'
  param :id, :number, required: true, desc: 'id of the requested company'
  returns code: 200, desc: "a successful response" do
    property :company, Hash do
      property :id, Integer, "An integer value"
      property :name, String, "A string value"
      property :cui, String, "A string value"
      property :status, Company.statuses.keys, "One of possible string values"
    end
  end
  def show
    # Logare acces
    Rails.logger.info "User #{current_user.id} accessed 'show' for company id #{params[:id]} at #{Time.now}"

    if @company
      # Logare răspuns
      Rails.logger.info "User #{current_user.id} received company details response 200 OK at #{Time.now} for company id #{params[:id]}"
    else
      # Logare eroare
      Rails.logger.info "User #{current_user.id} received response 404 Not Found at #{Time.now} for company id #{params[:id]}"
    end
  end

  private

  def authorize_user
    case action_name
    when 'create'
      head 403 unless current_user.patron?
    when 'update', 'destroy'
      head 403 unless current_user.contabil_sef?
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_company
    @company = current_user.visible_companies.find_by(id: params[:id])
    head 404 unless @company
  end

  # Only allow a list of trusted parameters through.
  def company_params
    params.require(:company).permit(:name, :cui, :status)
  end
end
