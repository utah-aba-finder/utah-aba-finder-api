require 'rails_helper'

RSpec.describe Provider, type: :model do

  describe 'relationships' do
    it { should have_many(:counties) }
    it { should have_many(:locations) }
    it { should have_many(:provider_insurances) }
    it { should have_many(:insurances).through(:provider_insurances) }
  end
end