Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/leads' => 'leads#index'
  get '/leads/:id' => 'leads#show'
  post '/leads' => 'leads#create'
end
