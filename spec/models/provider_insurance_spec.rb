require 'rails_helper'

RSpec.describe ProviderInsurance, type: :model do

  describe 'relationships' do
    it { should belong_to(:provider) }
    it { should belong_to(:insurance) }
  end
end