Safehood::Application.routes.draw do
  resources :messages, :only=>[:index,:show,:new,:create] do
    collection do
      post "receive"
      post "voice"
    end
  end
  
  root :to=> "application#index"
  post "create_user", :to=> 'application#create_user'
  
  match 'about' => 'application#about'
  match 'privacy' => 'application#privacy'
end
