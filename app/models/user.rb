class User < ApplicationRecord
  devise :registerable,
         :rememberable, :authenticatable,
         :omniauthable, :omniauth_providers => [:github]

  has_many :pull_request_reviews, foreign_key: :reviewer_remote_id, primary_key: :uid

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.name = auth.info.name   # assuming the user model has a name
    end
  end
end
