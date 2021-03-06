class User < ApplicationRecord
  has_many :quizzes
  has_many :ratings
  has_many :quiz_ratings, through: :quizzes
  has_many :drinks, through: :ratings
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable, :omniauth_providers => [:facebook]

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.image = auth.info.image
      user.email = auth.info.email
      user.password = Devise.friendly_token[0,20]
    end
  end

  def prepare_rating(drink)
    ratings.where("ratings.drink_id = ?", drink.id).first_or_initialize(drink_id: drink.id)
  end

  def drink_to_like

  end

  def drink_to_like=(drink_id)
    ratings.find_or_create_by(drink_id: drink_id.to_i).update(score: 1)
  end

  def ratings_attributes=(ratings_attributes)
    binding.pry
  end

  def liked_drinks
    # Drink.joins("INNER JOIN ratings ON ratings.drink_id = drinks.id INNER JOIN users ON users.id = ratings.user_id WHERE users.id = ? GROUP BY drinks.id HAVING ratings.score = 1", self.id)
    Drink.joins(ratings: :user).where(users: { id: self.id }).group("drinks.id, ratings.score").having(ratings: { score: 1 })

  end

  def disliked_drinks
    Drink.joins(:users).where(users: { id: self.id }).group("drinks.id, ratings.score").having(ratings: { score: -1 })
  end

  def recommended_drinks
    Drink.joins(:users).where(users: { id: self.id }).group("drinks.id, ratings.recommended").having(ratings: { recommended: true })
  end

  def liked_ingredients
    Ingredient.joins(drinks: :users).where(users: { id: self.id }).group("ingredients.id, ratings.score").having(ratings: { score: 1 })
  end

  def disliked_ingredients
    Ingredient.joins(drinks: :users).where(users: { id: self.id }).group("ingredients.id, ratings.score").having(ratings: { score: -1 })
  end

  def add_liked_drink(attributes)
    drink_id = attributes.keys.find {|k| k.match(/^\d+$/)}.to_i
    self.ratings.where(drink_id: drink_id).first_or_create.update(score: 1)
    self.save
    drink_id
  end

end
