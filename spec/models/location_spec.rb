require 'rails_helper'

RSpec.describe Location, type: :model do

  describe 'relationships' do
    it { should belong_to(:provider) }
  end
end