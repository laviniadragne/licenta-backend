require 'fcm'

class Api::V1::PatronController < Api::V1::ApiController
  before_action :authorize_user
  protect_from_forgery with: :null_session,
    if: Proc.new { |c| c.request.format =~ %r{application/json} }

  api :POST, "/patron/create_company", "Rol patron: Patronul cere sa inregistreze o companie"
  param :company, Hash, :required => true do
    param :name, String, "Name of a :resource", required: true 
    param :cui, String, "CUI", required: true 
  end
  returns code: 200, desc: "a successful response" do
    property :company, Hash do
      property :id, Integer, "An integer value"
      property :name, String, "A string value"
      property :cui, String, "A string value"
      property :status, ["cerere"], "One of possible string values"
    end
  end
  def create_company
    @company = Company.new(company_params)
    logger.info("Attempting to create company with name: #{company_params[:name]} and CUI: #{company_params[:cui]}")
    
    # Patronul trebuie sa aiba toate drepturile pe rapoarte
    @company.company_users.build(user: current_user, status: "aprobat", meta_data: {"categories" => Document::REPORTS})
    if @company.save
      logger.info("Company created successfully with ID: #{@company.id}")
      # Trimite notificare de push pentru toti contabilii
      fcm_push_notification(company_params[:name], company_params[:cui])
      render json: { company: @company.serialize }
    else
      logger.error("Error creating company: #{@company.errors.full_messages.join(", ")}")
      render json: @company.errors, status: :unprocessable_entity
    end
  end

  api :GET, "/patron/list_company_requests", "Rol patron: Listare cereri inregistrare companii in asteptare"
  def list_company_requests
        # doar in asteptare
    logger.info("Fetching company registration requests for patron: #{current_user.id}")
    render json: current_user.companies.cerere.map(&:serialize)
    # in asteptare si refuzate
    # render json: (current_user.companies.cerere.or(current_user.companies.refuzat)).map(&:serialize)
  end

  api :GET, "/patron/list_join_requests", "Rol patron: Listare cereri aplicare angajati in asteptare pe 1 firma"
  def list_join_requests
    @company = current_user.companies.find(params[:company_id])
    logger.info("Fetching join requests for company ID: #{@company.id}")
    render json: @company.company_users.cerere.map(&:serialize)
  end

  api :POST, "/patron/accept_join", "Rol patron: Accepta o aplicatie angajat in companie"
  param :company_id, Integer, "Id-ul companiei", required: true
  param :company_user_id, Integer, "ID-ul cererii din list_join_requests", required: true
  def accept_join
    @company = current_user.companies.find(params[:company_id])
    @company_user = @company.company_users.find_by(id: params[:company_user_id], status: "cerere")
    
    if @company_user.update(status: "aprobat")
      logger.info("Employee ID: #{@company_user.user_id} accepted to join company ID: #{@company.id}")
      render json: @company_user.serialize
    else
      logger.error("Error accepting join request for user ID: #{@company_user.user_id}")
      render json: @company_user.errors, status: :unprocessable_entity
    end
  end

  api :POST, "/patron/reject_join", "Rol patron: Refuza o aplicatie angajat in companie"
  param :company_id, Integer, "Id-ul companiei", required: true
  param :company_user_id, Integer, "ID-ul cererii din list_join_requests", required: true  
  def reject_join
    @company = current_user.companies.find(params[:company_id])
    @company_user = @company.company_users.find_by(id: params[:company_user_id], status: "cerere")
    
    if @company_user.destroy
      logger.info("Join request for user ID: #{@company_user.user_id} rejected from company ID: #{@company.id}")
      head 204
    else
      logger.error("Error rejecting join request for user ID: #{@company_user.user_id}")
      render json: @company_user.errors, status: :unprocessable_entity
    end
  end

  api :GET, "/patron/list_users", "Rol patron: Listeaza angajatii care au acces in 1 companie"
  def list_users
    @company = current_user.companies.find(params[:company_id])
    logger.info("Fetching users for company ID: #{@company.id}")
    render json: @company.users.angajat.joins(:company_users).where("company_users.status = 1").distinct.map(&:serialize)
  end

  api :POST, "/patron/remove_user", "Rol patron: Sterge accesul unui angajat din 1 companie"
  param :company_id, Integer, "Id-ul companiei", required: true
  param :user_id, Integer, "ID-ul angajatului obtinut din list_users", required: true 
  def remove_user
    @company = current_user.companies.find(params[:company_id])
    @company_user = @company.company_users.find_by(user_id: params[:user_id])
    
    if @company_user.nil?
      logger.warn("User ID: #{params[:user_id]} not found in company ID: #{@company.id}")
      render json: {error: "User not found for this company"}, status: :not_found
      return
    end
    
    if @company_user.destroy
      logger.info("User ID: #{params[:user_id]} removed from company ID: #{@company.id}")
      head 204
    else
      logger.error("Error removing user ID: #{params[:user_id]} from company ID: #{@company.id}")
      render json: {errors: {remove_user: 'error'}}, status: :unprocessable_entity
    end
  end

  api :POST, "/patron/update_roles", "Modifica rolurile unui angajat in 1 companie"
  param :company_id, Integer, "Id-ul companiei", required: true
  param :user_id, Integer, "ID-ul angajatului obtinut din list_users", required: true 
  # param :roles, Array, "Categoriile de documente la care are acces", optional: true
  def update_roles
    @company = current_user.companies.find(params[:company_id])
    @company_user = @company.company_users.find_by(user_id: params[:user_id])
    
    if @company_user.nil?
      logger.warn("User ID: #{params[:user_id]} not found in company ID: #{@company.id}")
      render json: {error: "User not found for this company"}, status: :not_found
      return
    end
    
    @company_user.meta_data ||= {}
    @company_user.meta_data[:categories] ||= (params[:roles] || [])
    
    if @company_user.save
      logger.info("User ID: #{params[:user_id]} roles updated for company ID: #{@company.id}")
      render json: @company_user.serialize
    else
      logger.error("Error updating roles for user ID: #{params[:user_id]} in company ID: #{@company.id}")
      render json: {errors: @company_user.errors}, status: :unprocessable_entity
    end
  end

  api :GET, "/patron/view_roles", "Vezi toate drepturile unui angajat in 1 companie"
  def view_roles
    @company = current_user.companies.find(params[:company_id])
    @company_user = @company.company_users.find_by(user_id: params[:user_id])
    
    if @company_user.meta_data.nil? || @company_user.meta_data.empty?
      roles = []
    else
      roles = @company_user.meta_data["categories"]
    end

    logger.info("Fetching roles for user ID: #{params[:user_id]} in company ID: #{@company.id}")
    render json: { roles: roles }
  end

  api :DELETE, "/patron/remove", "Sterge patronu'"
  def remove
    companies = current_user.companies

    for company in companies do
      documents = company.documents

      for document in documents do
        document.destroy
      end
      
      company_users = CompanyUser.where(company_id: company.id)

      for company_user in company_users do
        company_user.destroy
      end

      company.destroy
    end

    current_user.destroy
  end

  private

  def company_params
    params.require(:company).permit(:name, :cui)
  end

  def authorize_user
    head 403 unless current_user.patron?
  end

  def fcm_push_notification(firm_name, firm_cui)
    logger.info("Sending push notification for company: #{firm_name} (CUI: #{firm_cui}) to all accountants")
    
    firebase_server_key = "AAAA_xnnZsI:APA91bHHigg8O9j4Tr0kWYkm6wtzyEB_7QqMTrhZrpuBSoPTFTeeyUTdEUIeh_XaciIQKVBKv9voXtw4PQR1i22jbJbPK9KsDYTY2HI6X6Tp2TAjx7CuG9OiZwiPdQCtDVzfgxLJZLQl"
    fcm_client = FCM.new(firebase_server_key)
    message = "Cerere in asteptare noua pentru firma cu numele: #{firm_name} si cuiul: #{firm_cui}"
    image = nil
    options = { priority: 'high',
                data: { message: message, icon: image },
                notification: { 
                body: message,
                sound: 'default',
                icon: image,
                tag: 'cerere'
                }
              }
    registration_ids = User.where(role: ['contabil', 'contabil_sef']).pluck(:firebase_id)
    registration_ids = [] if registration_ids.nil?
    registration_ids = registration_ids.compact
    registration_ids.each_slice(20) do |registration_id|
        response = fcm_client.send(registration_id, options)
        puts response
        logger.info("Push notification response: #{response}")
    end
  end
end
