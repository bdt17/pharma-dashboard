class User < ApplicationRecord
  require 'devise'
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
