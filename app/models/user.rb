class User < ApplicationRecord
  # Phase 10: Devise stub - Full auth Q2 2026
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def admin?
    email == "admin@pharmatransport.com"
  end
end
