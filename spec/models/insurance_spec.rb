require 'rails_helper'

RSpec.describe Insurance, type: :model do

  describe 'relationships' do
    it { should have_many(:provider_insurances) }
    it { should have_many(:providers).through(:provider_insurances) }
  end
end