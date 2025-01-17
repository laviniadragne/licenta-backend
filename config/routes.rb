Rails.application.routes.draw do

  put 'users/edit_account', to: 'users#edit_account'

  apipie
  namespace :api, defaults: {format: :json} do
    namespace :v1 do
      root to: 'index#index'
      resources :contabili
      resources :contabil do
        collection do
          get 'list_accountants'
          post 'add_accountant'
          post 'remove_accountant'
          get 'list_company_requests'
          post 'approve_company'
          post 'reject_company'
        end
      end
      resources :patron do
        collection do
          post 'create_company'
          get 'list_company_requests'
          get 'list_join_requests'
          post 'accept_join'
          post 'reject_join'
          get 'list_users'
          post 'remove_user'
          post 'update_roles'
          get 'view_roles'
          delete 'remove'
        end
      end
      resources :angajat do
        collection do
          post 'join_company'
          get 'list_requests'
          delete 'remove'
        end
      end
      resources :companies do
        resources :documents do
          collection do
            get 'list_categories'
            get 'list_documents'
            get 'list_reports'
            get 'list_reports_by_category'
            get 'list_documents_by_issue_date'
            get 'list_document'
            post 'upload_document'
            post 'approve_document'
            delete 'remove_document'
          end
        end
      end
    end
  end
  root to: 'index#index'

  devise_for :users,
             controllers: {
                 sessions: 'users/sessions',
                 registrations: 'users/registrations'
             }

end
