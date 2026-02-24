require 'rails_helper'

RSpec.describe FinancialProfileCalculator do
  let(:household) { create(:household) }
  let(:profile) { create(:financial_profile, household: household, salary_person_1: 2800, salary_person_2: 2200, monthly_charges: 500, proposed_rate: 3.5, desired_duration_years: 25, personal_contribution: 30_000, remaining_savings: 10_000) }

  subject { described_class.new(profile) }

  describe '#max_monthly_payment' do
    it 'equals 35% of total income' do
      total = profile.total_monthly_income
      expected = (total * 35.0 / 100).round(2)
      expect(subject.max_monthly_payment).to eq(expected)
    end
  end

  describe '#borrowing_capacity' do
    it 'returns a positive amount' do
      expect(subject.borrowing_capacity).to be > 0
    end

    it 'increases with higher income' do
      low = described_class.new(profile).borrowing_capacity
      profile.update!(salary_person_1: 5000)
      high = described_class.new(profile.reload).borrowing_capacity
      expect(high).to be > low
    end
  end

  describe '#current_debt_ratio' do
    it 'calculates ratio of charges to income' do
      expected = (500.0 / 5000 * 100).round(2)
      expect(subject.current_debt_ratio).to eq(expected)
    end
  end

  describe '#remaining_to_live' do
    it 'returns positive value for normal scenario' do
      expect(subject.remaining_to_live).to be > 0
    end
  end

  describe '#call' do
    it 'returns complete financial analysis' do
      result = subject.call
      expect(result).to include(:borrowing_capacity, :debt_ratio, :max_monthly_payment, :remaining_to_live, :optimal_budget, :danger_indicators)
    end
  end

  describe '#danger_indicators' do
    it 'warns when savings are low' do
      profile.update!(remaining_savings: 1000)
      indicators = described_class.new(profile.reload).danger_indicators
      messages = indicators.map { |i| i[:message] }
      expect(messages).to include(a_string_matching(/épargne/i))
    end
  end
end
