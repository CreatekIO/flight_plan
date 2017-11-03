class User < ApplicationRecord
  devise :registerable,
         :rememberable, :authenticatable,
         :omniauthable, :omniauth_providers => [:github]

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.name = auth.info.name   # assuming the user model has a name
    end
  end
end
