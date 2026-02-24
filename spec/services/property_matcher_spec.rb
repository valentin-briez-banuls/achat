require 'rails_helper'

RSpec.describe PropertyMatcher do
  let(:household) { create(:household) }
  let(:criteria) { create(:property_criterion, household: household, max_budget: 300_000, min_surface: 60, min_bedrooms: 2, outdoor_required: true, parking_required: false, min_energy_class: 'D') }

  describe '#call' do
    it 'scores a perfect match highly' do
      property = create(:property, :with_scores, household: household, price: 250_000, surface: 75, bedrooms: 3, has_outdoor: true, energy_class: 'C',
                        score_neighborhood: 5, score_view: 5, score_orientation: 5, score_renovation: 5, score_quietness: 5, score_brightness: 5)

      score = described_class.new(property, criteria).call
      expect(score.total_score).to be >= 75
      expect(score.compatibility).to eq('stricte')
    end

    it 'scores an over-budget property low' do
      property = create(:property, :with_scores, household: household, price: 500_000, surface: 75, bedrooms: 3, has_outdoor: true, energy_class: 'C')

      score = described_class.new(property, criteria).call
      expect(score.total_score).to be < 75
    end

    it 'marks non-compatible when mandatory criteria fail' do
      property = create(:property, household: household, price: 600_000, surface: 30, bedrooms: 0, has_outdoor: false, energy_class: 'G')

      score = described_class.new(property, criteria).call
      expect(score.compatibility).to eq('non_compatible')
    end

    it 'creates a PropertyScore record' do
      property = create(:property, :with_scores, household: household, price: 250_000, surface: 65, bedrooms: 2, has_outdoor: true, energy_class: 'D')

      expect { described_class.new(property, criteria).call }.to change(PropertyScore, :count).by(1)
    end

    it 'updates existing score on re-calculation' do
      property = create(:property, :with_scores, household: household, price: 250_000, surface: 65, bedrooms: 2, has_outdoor: true, energy_class: 'D')

      described_class.new(property, criteria).call
      expect { described_class.new(property.reload, criteria).call }.not_to change(PropertyScore, :count)
    end
  end
end
