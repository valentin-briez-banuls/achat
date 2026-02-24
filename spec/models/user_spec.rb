require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:email) }
  end

  describe 'associations' do
    it { should belong_to(:household).optional }
  end

  describe '#full_name' do
    it 'returns first and last name' do
      user = build(:user, first_name: 'Jean', last_name: 'Dupont')
      expect(user.full_name).to eq('Jean Dupont')
    end
  end
end
