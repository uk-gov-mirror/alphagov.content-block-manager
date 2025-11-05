Rails.application.routes.draw do
  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response
  mount Flipflop::Engine => "/flipflop"

  scope via: :all do
    match "/400", to: "errors#bad_request"
    match "/403", to: "errors#forbidden"
    match "/404", to: "errors#not_found"
    match "/422", to: "errors#unprocessable_content"
    match "/500", to: "errors#internal_server_error"
  end

  namespace :admin do
    post "preview" => "preview#preview"
  end

  root to: "documents#index", via: :get

  resources :users, only: %i[show]

  get "content-id/:content_id", to: "documents#content_id", as: :content_id
  resources :documents, only: %i[index show new], path_names: { new: "(:block_type)/new" }, path: "" do
    collection do
      post :new_document_options_redirect
    end
    resources :editions, only: %i[new create]
    get "schedule/edit", to: "documents/schedule#edit", as: :schedule_edit
    put "schedule", to: "documents/schedule#update", as: :update_schedule
    patch "schedule", to: "documents/schedule#update"
  end
  resources :editions, only: %i[new create destroy], path_names: { new: ":block_type/new" } do
    member do
      get :preview, to: "editions#preview"

      # Workflow actions
      resources :workflow, only: %i[show update], controller: "editions/workflow", param: :step do
        collection do
          get :cancel, to: "editions/workflow#cancel"
        end
      end

      # Embedded object actions
      get "embedded-objects/(:object_type)/new", to: "editions/embedded_objects#new", as: :new_embedded_object
      post "embedded-objects", to: "editions/embedded_objects#new_embedded_objects_options_redirect", as: :new_embedded_objects_options_redirect
      post "embedded-objects/:object_type", to: "editions/embedded_objects#create", as: :create_embedded_object
      get "embedded-objects/:object_type/:object_title/edit", to: "editions/embedded_objects#edit", as: :edit_embedded_object
      put "embedded-objects/:object_type/:object_title", to: "editions/embedded_objects#update", as: :embedded_object

      # Host content preview actions
      get "host-content/:host_content_id/preview", to: "editions/host_content#preview", as: :host_content_preview
      post "host-content/:host_content_id/form_handler", to: "editions/host_content#form_handler", as: :host_content_preview_form_handler

      # Reorder actions
      get :order, to: "editions/order#edit", as: :order_edit
      put :order, to: "editions/order#update", as: :order_update
    end
  end
end
