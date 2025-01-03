class Insurance < ApplicationRecord
  has_many :provider_insurances, dependent: :destroy
  has_many :providers, through: :provider_insurances

  def initialize_provider_insurance
    Provider.all.each do |p|
      ProviderInsurance.find_or_create_by!(provider_id: p.id, insurance_id: self.id)
    end
  end
end
