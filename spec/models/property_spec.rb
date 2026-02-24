require 'rails_helper'

RSpec.describe Property, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:surface) }
    it { should validate_presence_of(:city) }
    it { should validate_presence_of(:postal_code) }
    it { should validate_numericality_of(:price).is_greater_than(0) }
    it { should validate_numericality_of(:surface).is_greater_than(0) }
  end

  describe 'associations' do
    it { should belong_to(:household) }
    it { should have_one(:property_score) }
    it { should have_many(:simulations) }
    it { should have_many(:visits) }
    it { should have_many(:offers) }
  end

  describe '#price_per_sqm' do
    it 'calculates price per square meter' do
      property = build(:property, price: 200_000, surface: 80)
      expect(property.price_per_sqm).to eq(2500)
    end
  end

  describe '#effective_price' do
    it 'returns price when fees included' do
      property = build(:property, price: 200_000, agency_fees: 10_000, agency_fees_included: true)
      expect(property.effective_price).to eq(200_000)
    end

    it 'adds fees when not included' do
      property = build(:property, price: 200_000, agency_fees: 10_000, agency_fees_included: false)
      expect(property.effective_price).to eq(210_000)
    end
  end
end
