require 'rails_helper'

RSpec.describe NotaryFeeCalculator do
  describe '#total' do
    context 'ancien property' do
      it 'calculates ~7-8% for ancien' do
        calc = described_class.new(price: 250_000, condition: 'ancien')
        result = calc.call
        percentage = result[:percentage]
        expect(percentage).to be_between(6.5, 9.0)
      end
    end

    context 'neuf property' do
      it 'calculates ~2-3% for neuf' do
        calc = described_class.new(price: 250_000, condition: 'neuf')
        result = calc.call
        percentage = result[:percentage]
        expect(percentage).to be_between(1.5, 4.0)
      end
    end

    it 'neuf fees are significantly lower than ancien' do
      ancien = described_class.new(price: 300_000, condition: 'ancien').total
      neuf = described_class.new(price: 300_000, condition: 'neuf').total
      expect(neuf).to be < ancien
    end
  end

  describe '#call' do
    it 'returns detailed breakdown' do
      result = described_class.new(price: 200_000, condition: 'ancien').call
      expect(result).to include(:emoluments, :droits_mutation, :contribution_securite, :debours, :total, :percentage)
      expect(result[:emoluments]).to be > 0
      expect(result[:droits_mutation]).to be > 0
    end
  end
end
