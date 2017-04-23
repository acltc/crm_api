Rails.application.routes.draw do
  resources :leads
  get '/' => 'leads#next'
  get '/no_leads' => 'leads#no_leads'
  get '/token' => 'leads#token'
  post '/voice' => 'leads#voice'

  post '/incoming_voice' => 'webhooks#incoming_voice'
  post '/incoming_text' => 'webhooks#incoming_text'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace :api do
    namespace :v1 do
      get '/leads' => 'leads#index'
      get '/leads/:id' => 'leads#show'
      post '/leads' => 'leads#create'
    end
  end

end
