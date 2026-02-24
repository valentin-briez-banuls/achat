require 'rails_helper'

RSpec.describe PTZCalculator do
  let(:default_params) do
    {
      zone: 'B1',
      household_size: 2,
      fiscal_income: 45_000,
      property_type: :appartement,
      operation_cost: 250_000,
      condition: 'neuf'
    }
  end

  describe '#eligible?' do
    it 'is eligible for valid params' do
      calc = described_class.new(**default_params)
      expect(calc.eligible?).to be true
    end

    it 'is not eligible when income exceeds limit' do
      calc = described_class.new(**default_params.merge(fiscal_income: 200_000))
      expect(calc.eligible?).to be false
    end

    it 'is not eligible in invalid zone' do
      calc = described_class.new(**default_params.merge(zone: 'Z'))
      expect(calc.eligible?).to be false
    end

    it 'is not eligible for ancien in zone A' do
      calc = described_class.new(**default_params.merge(zone: 'A', condition: 'ancien'))
      expect(calc.eligible?).to be false
    end

    it 'is eligible for ancien avec travaux in zone B2' do
      calc = described_class.new(**default_params.merge(zone: 'B2', condition: 'ancien'))
      expect(calc.eligible?).to be true
    end
  end

  describe '#max_amount' do
    it 'calculates correct max amount' do
      calc = described_class.new(**default_params)
      result = calc.call
      expect(result[:max_amount]).to be > 0
      expect(result[:max_amount]).to be <= 250_000
    end

    it 'respects operation cost limit' do
      calc = described_class.new(**default_params.merge(operation_cost: 100_000))
      result = calc.call
      # PTZ should be based on min(operation_cost, limit)
      expect(result[:max_amount]).to be <= 100_000
    end
  end

  describe '#call' do
    it 'returns complete result' do
      result = described_class.new(**default_params).call
      expect(result).to include(:eligible, :max_amount, :quotite, :income_tranche, :repayment_terms)
    end

    it 'includes repayment terms when eligible' do
      result = described_class.new(**default_params).call
      expect(result[:repayment_terms]).to include(:total_years, :deferred_years, :repayment_years)
    end

    it 'provides reason when not eligible' do
      result = described_class.new(**default_params.merge(fiscal_income: 999_999)).call
      expect(result[:eligible]).to be false
      expect(result[:reason]).to be_present
    end
  end
end
