Safehood::Application.routes.draw do
  resources :messages, :only=>[:index,:show,:new,:create] do
    collection do
      post "receive"
      post "voice"
    end
  end
  
  
  post "create_user", :to=> 'application#create_user'
  get 'about' => 'application#about'
  get 'privacy' => 'application#privacy'
  
  root :to=> "application#index"
end
