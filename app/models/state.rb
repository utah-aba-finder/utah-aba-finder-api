class State < ApplicationRecord
  has_many :counties, dependent: :destroy

  validates :name, presence: true
  validates :abbreviation, presence: true, length: { is: 2 }
end