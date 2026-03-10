class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end


  def create_stripe_customer
    Stripe::Customer.create(email: email)
  end
