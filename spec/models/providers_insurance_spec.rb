require 'rails_helper'

RSpec.describe ProvidersInsurance, type: :model do

  describe 'relationships' do
    it { should belong_to(:provider) }
    it { should belong_to(:insurance) }
  end
end