class Location < ApplicationRecord
  belongs_to :provider
  has_many :locations_practice_types, dependent: :destroy
  has_many :practice_types, through: :locations_practice_types
  
  # Predefined waitlist options for consistent user experience
  WAITLIST_OPTIONS = [
    "No waitlist",
    "1-2 weeks", 
    "2-4 weeks",
    "1-3 months",
    "3-6 months",
    "6+ months",
    "Not accepting new clients",
    "Contact for availability"
  ].freeze
  
  # Validations for waitlist fields
  validates :in_home_waitlist, inclusion: { in: WAITLIST_OPTIONS }, allow_blank: true
  validates :in_clinic_waitlist, inclusion: { in: WAITLIST_OPTIONS }, allow_blank: true
  
  # Scopes for filtering by waitlist status
  scope :accepting_new_clients, -> { where.not(in_home_waitlist: "Not accepting new clients").where.not(in_clinic_waitlist: "Not accepting new clients") }
  scope :no_waitlist, -> { where(in_home_waitlist: "No waitlist").or(where(in_clinic_waitlist: "No waitlist")) }
  scope :short_waitlist, -> { where(in_home_waitlist: ["1-2 weeks", "2-4 weeks"]).or(where(in_clinic_waitlist: ["1-2 weeks", "2-4 weeks"])) }
end
