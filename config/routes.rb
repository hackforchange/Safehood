Safehood::Application.routes.draw do
  resources :messages, :only=>[:index,:show,:new,:create] do
    collection do
      post "receive"
    end
  end
  
  match "messages/voice", :to=>"messages#voice"
  
  root :to=> "application#index"
end
