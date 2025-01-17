class Api::V1::AngajatController < Api::V1::ApiController
  before_action :authorize_user
  protect_from_forgery with: :null_session,
    if: Proc.new { |c| c.request.format =~ %r{application/json} }

    api :POST, '/angajat/join_company', 'Rol angajat: Angajatul aplica la o companie'
    param :cui, String, 'CUI'
    returns code: 204, desc: "no content"
    error code: 400, desc: "Bad Request",  meta: {errors: 'Validation errors'}
  
    def join_company
      company = Company.find_by(cui: params[:cui])
      company_user = current_user.company_users.new(company: company)
      
      # Logare acces
      Rails.logger.info "User #{current_user.id} accessed 'join_company' at #{Time.now}. CUI: #{params[:cui]}"

      if company_user.save
        # Logare răspuns
        Rails.logger.info "User #{current_user.id} received response 204 No Content at #{Time.now} for 'join_company'."
        head :no_content
      else
        # Logare răspuns
        Rails.logger.info "User #{current_user.id} received response 400 Bad Request at #{Time.now} for 'join_company'."
        render json: company_user.errors, status: 400
      end
    end

    # My Firm Requests
    api :GET, '/angajat/list_requests', 'Rol angajat: Listeaza aplicatiile in companii in asteptare'
    def list_requests
      # Logare acces
      Rails.logger.info "User #{current_user.id} accessed 'list_requests' at #{Time.now}"
      
      requests = current_user.company_users.cerere.map(&:serialize)
      
      # Logare răspuns
      Rails.logger.info "User #{current_user.id} received response 200 OK at #{Time.now} for 'list_requests'. Requests: #{requests.count}"
      
      render json: requests
    end

    api :DELETE, '/angajat/remove', 'Delete angajat'
    def remove
      current_user.destroy!
    end

    private
   
    def authorize_user
        head 403 unless current_user.angajat?
    end
end