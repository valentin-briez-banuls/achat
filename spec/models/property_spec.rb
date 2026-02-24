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
    it { should have_many(:price_histories) }
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

  describe '#price_drop_percentage' do
    it 'returns nil when fewer than 2 history entries' do
      property = create(:property, price: 200_000)
      create(:property_price_history, property: property, price: 200_000, scraped_at: 1.month.ago)
      expect(property.price_drop_percentage).to be_nil
    end

    it 'calculates percentage drop from first to last entry' do
      property = create(:property, price: 180_000)
      create(:property_price_history, property: property, price: 200_000, scraped_at: 2.months.ago)
      create(:property_price_history, property: property, price: 180_000, scraped_at: 1.month.ago)
      expect(property.price_drop_percentage).to eq(10.0)
    end

    it 'returns negative percentage for a price increase' do
      property = create(:property, price: 220_000)
      create(:property_price_history, property: property, price: 200_000, scraped_at: 2.months.ago)
      create(:property_price_history, property: property, price: 220_000, scraped_at: 1.month.ago)
      expect(property.price_drop_percentage).to be < 0
    end
  end

  describe '#price_dropped?' do
    it 'returns true when price has dropped' do
      property = create(:property, price: 180_000)
      create(:property_price_history, property: property, price: 200_000, scraped_at: 2.months.ago)
      create(:property_price_history, property: property, price: 180_000, scraped_at: 1.month.ago)
      expect(property.price_dropped?).to be true
    end

    it 'returns false when no price drop' do
      property = create(:property, price: 200_000)
      create(:property_price_history, property: property, price: 200_000, scraped_at: 2.months.ago)
      create(:property_price_history, property: property, price: 200_000, scraped_at: 1.month.ago)
      expect(property.price_dropped?).to be false
    end
  end

  describe '#record_price_history!' do
    it 'creates a history entry on first call' do
      property = create(:property, price: 200_000)
      expect { property.record_price_history! }.to change { property.price_histories.count }.by(1)
    end

    it 'does not create a duplicate entry when price is unchanged' do
      property = create(:property, price: 200_000)
      property.record_price_history!
      expect { property.record_price_history! }.not_to change { property.price_histories.count }
    end

    it 'creates a new entry when price changes' do
      property = create(:property, price: 200_000)
      property.record_price_history!
      property.update!(price: 190_000)
      expect { property.record_price_history! }.to change { property.price_histories.count }.by(1)
    end
  end
end
