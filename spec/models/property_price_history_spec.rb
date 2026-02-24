require "rails_helper"

RSpec.describe PropertyPriceHistory, type: :model do
  describe "associations" do
    it { should belong_to(:property) }
  end

  describe "validations" do
    it { should validate_presence_of(:price) }
    it { should validate_numericality_of(:price).is_greater_than(0) }
    it { should validate_presence_of(:scraped_at) }
    it { should validate_presence_of(:source) }
    it { should validate_inclusion_of(:source).in_array(%w[scraper manual]) }
  end
end
