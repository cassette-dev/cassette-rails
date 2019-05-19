Rails.application.routes.draw do
  match '/' => 'cassette#index', via: [:get, :post]
  match '/json' => 'cassette#json', via: [:get, :post]
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
