Safehood::Application.routes.draw do
  resources :messages, :only=>[:index,:show,:new,:create]
  root :to=> "messages#index"
end
