require 'sidekiq/web'

DplaEtl::Application.routes.draw do

  devise_for :users, path_names: {sign_in: "login", sign_out: "logout"}

  authenticate :user do
    mount Sidekiq::Web, at: '/batches'
  end

  root 'import_jobs#index'

  resources :import_jobs
  resources :import_batches
  resources :profiles
  resources :records

  # Override the record show route to accept some params to allow for
  # specifying certain records
  get 'records/:id/(:version_id)' => 'records#show'
  post 'import_batches/extract' => 'import_batches#extract'
  post 'import_batches/transform/:id' => 'import_batches#transform'
  get  'transformation_batches/import_batch_records/:import_batch_id' => 'transformation_batches#import_batch_records'
  post 'import_batches/download_transformations/:id' => 'import_batches#download_transformations'
  get  'import_batch/records/:job_id/:id' => 'import_batches#batch_records'
  post 'run_workers' => 'import_jobs#run_workers', as: :run_workers
  post 'run_worker' => 'import_jobs#run_worker', as: :run_worker
  post 'stop_import_job' => 'import_jobs#cancel', as: :cancel_import
  post 'share_job' => 'import_jobs#share_job', as: :share_job
  post 'import_jobs/destroy_batches/:id' => 'import_jobs#destroy_batches'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end