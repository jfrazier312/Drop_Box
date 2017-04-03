Rails.application.routes.draw do

  root 'welcome#index'


  resources :users do
    resources :assets
    get "assets/get/:id" => "assets#get", :as => "download"
  end

  resources :posts do
    resources :comments
    member do
      get :like
      get :unlike
    end
  end
  resources :sessions

  # Login and Sessions routes
  get   '/login',   to: 'sessions#new'      #Describes the login screen
  post  '/login',   to: 'sessions#create'   #Handles actually logging in
  delete '/logout', to: 'sessions#destroy'  #Handles logging out

end
