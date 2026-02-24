require 'rails_helper'

RSpec.describe LoanCalculator do
  describe '#monthly_payment' do
    it 'calculates correct monthly payment for standard loan' do
      calc = described_class.new(principal: 200_000, annual_rate: 3.5, duration_years: 25)
      # Expected: ~1001€/month for 200k at 3.5% over 25 years
      expect(calc.monthly_payment).to be_between(990, 1010)
    end

    it 'returns 0 for zero principal' do
      calc = described_class.new(principal: 0, annual_rate: 3.5, duration_years: 25)
      expect(calc.monthly_payment).to eq(0)
    end

    it 'handles high rate correctly' do
      calc = described_class.new(principal: 200_000, annual_rate: 6.0, duration_years: 20)
      expect(calc.monthly_payment).to be_between(1400, 1450)
    end
  end

  describe '#total_cost' do
    it 'calculates total cost over loan lifetime' do
      calc = described_class.new(principal: 200_000, annual_rate: 3.5, duration_years: 25)
      expect(calc.total_cost).to be > 200_000
      expect(calc.total_cost).to be < 400_000
    end
  end

  describe '#total_interest' do
    it 'calculates total interest paid' do
      calc = described_class.new(principal: 200_000, annual_rate: 3.5, duration_years: 25)
      expect(calc.total_interest).to be > 50_000
    end
  end

  describe '.rate_impact' do
    it 'returns impact for various rate deltas' do
      results = described_class.rate_impact(principal: 200_000, duration_years: 25, base_rate: 3.5)
      expect(results).to be_an(Array)
      expect(results.length).to be >= 5
      # Higher rate = higher monthly payment
      payments = results.map { |r| r[:monthly_payment] }
      expect(payments).to eq(payments.sort)
    end
  end
end
