require 'rails_helper'

RSpec.describe Insurance, type: :model do

  describe 'relationships' do
    it { should have_many(:providers_insurance) }
    it { should have_many(:providers).through(:providers_insurance) }
  end
end