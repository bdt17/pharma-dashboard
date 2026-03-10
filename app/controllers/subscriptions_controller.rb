class SubscriptionsController < ApplicationController
  def index
    @plans = [
      {name: 'Starter', price: 99, features: '5 vehicles'},
      {name: 'Pro', price: 299, features: '50 vehicles'}, 
      {name: 'Enterprise', price: 499, features: '500 vehicles'}
    ]
  end
end
