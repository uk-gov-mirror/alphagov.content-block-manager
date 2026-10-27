require "govuk_sidekiq/gds_sso_middleware"

Rails.application.routes.draw do
  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response
  get "/accessibility-statement", to: "pages#accessibility_statement"
  get "/content-block-picker-demo", to: "pages#content_block_picker_demo"
  mount Flipflop::Engine => "/flipflop"
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  mount FactCheck::Engine => "/fact-check"
  mount BlockPreview::Engine => "/preview"
  mount GovukSidekiq::GdsSsoMiddleware, at: "/sidekiq"
  mount Api::Engine => "/api"

  scope via: :all do
    match "/400", to: "errors#bad_request"
    match "/403", to: "errors#forbidden"
    match "/404", to: "errors#not_found"
    match "/422", to: "errors#unprocessable_content"
    match "/500", to: "errors#internal_server_error"
  end

  namespace :admin do
    post "preview" => "preview#preview"

    namespace :metrics do
      get "host-content", to: "host_content#index", as: :host_content
    end
  end

  root to: "documents#index", via: :get

  resources :users, only: %i[show]

  get "content-id/:content_id", to: "documents#content_id", as: :content_id
  resources :documents, only: %i[index show new], path_names: { new: "(:block_type)/new" }, path: "" do
    collection do
      post :new_document_options_redirect
    end

    member do
      get "published_edition", to: "published_edition#show"
    end

    resources :editions, only: %i[new create]
    get "schedule/edit", to: "documents/schedule#edit", as: :schedule_edit
    put "schedule", to: "documents/schedule#update", as: :update_schedule
    patch "schedule", to: "documents/schedule#update"
  end

  namespace :v2 do
    concern :reviewable do
      resources :pre_publication_reviews, path: "pre-publication-reviews", only: %i[new create]
    end

    resources :time_period_editions, only: %i[new create]

    resources :documents, only: %i[index show] do
      constraints EditionTypeConstraints.new("V2::TimePeriodEdition") do
        resources :editions, only: %i[edit update], controller: "time_period_editions", concerns: :reviewable do
          resource :time_period_date_range, only: %i[edit update], as: "date_range", path: "date-range", controller: "time_period_date_ranges"
        end
      end
    end
  end

  resources :editions, only: %i[new create destroy], path_names: { new: ":block_type/new" } do
    member do
      get :preview, to: "editions#preview"

      get :delete, to: "editions#delete"

      # Workflow actions
      resources :workflow, only: %i[show update], controller: "editions/workflow", param: :step do
        collection do
          get :cancel, to: "editions/workflow#cancel"
        end
      end

      # record 2i Review outcomes
      get "review_outcomes/new", to: "editions/review_outcomes#new", as: :new_review_outcome
      post "review_outcomes", to: "editions/review_outcomes#create", as: :create_review_outcome
      get "review_outcomes/identify_performer", to: "editions/review_outcomes#identify_performer", as: :identify_performer_review_outcome
      put "review_outcomes", to: "editions/review_outcomes#update", as: :update_review_outcome

      # record fact check outcomes
      get "fact_check_outcomes/new", to: "editions/fact_check_outcomes#new", as: :new_fact_check_outcome
      post "fact_check_outcomes", to: "editions/fact_check_outcomes#create", as: :create_fact_check_outcome
      get "fact_check_outcomes/identify_performer", to: "editions/fact_check_outcomes#identify_performer", as: :identify_performer_fact_check_outcome
      put "fact_check_outcomes", to: "editions/fact_check_outcomes#update", as: :update_fact_check_outcome

      # State transitions
      resources :edition_status_transitions, only: [:create], controller: "editions/status_transitions"

      # Embedded objects actions (one-to-many)
      get "embedded-objects/(:object_type)/new", to: "editions/embedded_objects#new", as: :new_embedded_object
      post "embedded-objects", to: "editions/embedded_objects#new_embedded_objects_options_redirect", as: :new_embedded_objects_options_redirect
      post "embedded-objects/:object_type", to: "editions/embedded_objects#create", as: :create_embedded_object
      get "embedded-objects/:object_type/:object_title/edit", to: "editions/embedded_objects#edit", as: :edit_embedded_object
      put "embedded-objects/:object_type/:object_title", to: "editions/embedded_objects#update", as: :embedded_object

      # Embedded object actions (one-to-one)
      get "embedded-object/(:object_type)/new", to: "editions/embedded_object#new", as: :new_sole_embedded_object
      post "embedded-object/:object_type", to: "editions/embedded_object#create", as: :create_sole_embedded_object
      get "embedded-object/:object_type/edit", to: "editions/embedded_object#edit", as: :edit_sole_embedded_object
      put "embedded-object/:object_type/", to: "editions/embedded_object#update", as: :sole_embedded_object

      # Reorder actions
      get :order, to: "editions/order#edit", as: :order_edit
      put :order, to: "editions/order#update", as: :order_update

      # Regenerate fact check preview link
      put :fact_check_preview_link, to: "editions/fact_check_preview_link#update", as: :update_fact_check_preview_link
    end
  end
end
