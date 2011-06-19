Safehood::Application.routes.draw do
  resources :messages, :only=>[:index,:show,:new,:create] do
    collection do
      post "receive"
    end
  end
  
  root :to=> "application#index"
end
