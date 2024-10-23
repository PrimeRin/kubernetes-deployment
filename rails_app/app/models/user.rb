class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :email, type: String

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
