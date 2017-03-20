Rails.application.routes.draw do

  get'game', to: 'letters_numbers#game'

  get 'score', to: 'letters_numbers#score'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
