require 'rails_helper'

RSpec.describe Provider, type: :model do

  describe 'relationships' do
    it { should have_many(:counties) }
    it { should have_many(:locations) }
    it { should have_many(:providers_insurance) }
    it { should have_many(:insurances).through(:providers_insurance) }
  end
end