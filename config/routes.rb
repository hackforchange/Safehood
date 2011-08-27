Safehood::Application.routes.draw do
  scope "(:locale)", :locale => /en|es/ do
    resources :application
  end
  resources :messages, :only=>[:index,:show,:new,:create] do
    collection do
      post "receive"
      post "voice"
    end
  end
  
  
  post "create_user", :to=> 'application#create_user'
  get 'about' => 'application#about'
  get 'privacy' => 'application#privacy'
  get 'commands' => 'application#commands'
  
  match '/:locale' => 'application#index'
  root :to=> "application#index"
end
