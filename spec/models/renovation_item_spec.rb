require "rails_helper"

RSpec.describe RenovationItem, type: :model do
  subject(:item) { build(:renovation_item) }

  describe "associations" do
    it { is_expected.to belong_to(:property) }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:estimated_cost_min).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:estimated_cost_max).is_greater_than_or_equal_to(0) }

    it "is invalid when max < min" do
      item.estimated_cost_min = 10_000
      item.estimated_cost_max = 5_000
      expect(item).not_to be_valid
      expect(item.errors[:estimated_cost_max]).to be_present
    end

    it "is valid when max == min" do
      item.estimated_cost_min = 5_000
      item.estimated_cost_max = 5_000
      expect(item).to be_valid
    end
  end

  describe "#category_label" do
    it "returns French label for a known category" do
      item.category = :cuisine
      expect(item.category_label).to eq("Cuisine")
    end

    it "returns French label for salle_de_bain" do
      item.category = :salle_de_bain
      expect(item.category_label).to eq("Salle de bain")
    end
  end

  describe "#energy_upgrade?" do
    it "returns true for isolation" do
      item.category = :isolation
      expect(item.energy_upgrade?).to be true
    end

    it "returns true for fenetres" do
      item.category = :fenetres
      expect(item.energy_upgrade?).to be true
    end

    it "returns false for cuisine" do
      item.category = :cuisine
      expect(item.energy_upgrade?).to be false
    end
  end

  describe "#household" do
    it "delegates to property.household" do
      expect(item.household).to eq(item.property.household)
    end
  end
end
