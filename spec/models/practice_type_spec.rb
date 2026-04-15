require 'rails_helper'

RSpec.describe PracticeType, type: :model do
  describe ".canonical_display_name" do
    it "normalizes hyphenated or underscored ABA variants to ABA Therapy" do
      expect(described_class.canonical_display_name("aba-therapy")).to eq("ABA Therapy")
      expect(described_class.canonical_display_name("aba_therapy")).to eq("ABA Therapy")
      expect(described_class.canonical_display_name("aba therapy")).to eq("ABA Therapy")
    end

    it "leaves unknown labels unchanged" do
      expect(described_class.canonical_display_name("Pediatric Dentistry")).to eq("Pediatric Dentistry")
    end
  end

  it "applies canonical name before save" do
    pt = described_class.create!(name: "aba therapy")
    expect(pt.reload.name).to eq("ABA Therapy")
  end
end
