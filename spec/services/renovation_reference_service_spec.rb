require "rails_helper"

RSpec.describe RenovationReferenceService do
  describe ".estimate" do
    context "with a forfait category" do
      it "returns the fixed min/max" do
        result = described_class.estimate(:cuisine)
        expect(result[:min]).to eq(5_000)
        expect(result[:max]).to eq(20_000)
        expect(result[:unit]).to eq(:forfait)
      end
    end

    context "with a per_sqm category and surface provided" do
      it "multiplies the rate by the surface" do
        result = described_class.estimate(:sols, surface_sqm: 60)
        expect(result[:min]).to eq(25 * 60)
        expect(result[:max]).to eq(80 * 60)
        expect(result[:unit]).to eq(:per_sqm)
        expect(result[:surface]).to eq(60)
      end
    end

    context "with a per_sqm category and no surface" do
      it "returns the raw rate without multiplying" do
        result = described_class.estimate(:sols)
        expect(result[:min]).to eq(25)
        expect(result[:max]).to eq(80)
      end
    end

    context "with an unknown category" do
      it "returns nil" do
        expect(described_class.estimate(:unknown)).to be_nil
      end
    end
  end

  describe ".categories" do
    it "returns all 10 categories" do
      expect(described_class.categories.length).to eq(10)
      expect(described_class.categories).to include(:cuisine, :salle_de_bain, :isolation, :fenetres)
    end
  end

  describe ".benchmark_for" do
    it "returns the benchmark hash for a known category" do
      result = described_class.benchmark_for(:isolation)
      expect(result[:min]).to eq(20)
      expect(result[:unit]).to eq(:per_sqm)
    end

    it "returns nil for unknown category" do
      expect(described_class.benchmark_for(:unknown)).to be_nil
    end
  end
end
