require 'rails_helper'

RSpec.describe OldCounty, type: :model do

  describe 'relationships' do
    it { should belong_to(:provider) }
  end
end