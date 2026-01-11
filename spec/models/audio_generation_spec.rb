require 'rails_helper'

RSpec.describe AudioGeneration, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:text) }
    it { should validate_length_of(:text).is_at_most(5000) }
    it { should validate_inclusion_of(:status).in_array(%w[pending processing completed failed]) }
  end
  
  describe 'callbacks' do
    context 'before_validation on create' do
      it 'sets default status to pending' do
        audio_gen = AudioGeneration.new(text: 'Test')
        audio_gen.valid?
        expect(audio_gen.status).to eq('pending')
      end
      
      it 'sets default voice_id' do
        audio_gen = AudioGeneration.new(text: 'Test')
        audio_gen.valid?
        expect(audio_gen.voice_id).to eq('21m00Tcm4TlvDq8ikWAM')
      end
    end
  end
  
  describe 'scopes' do
    let!(:pending_gen) { create(:audio_generation) }
    let!(:completed_gen) { create(:audio_generation, :completed) }
    let!(:failed_gen) { create(:audio_generation, :failed) }
    
    it 'returns recent generations ordered by created_at desc' do
      expect(AudioGeneration.recent.first).to eq(failed_gen)
    end
    
    it 'filters by status' do
      expect(AudioGeneration.completed).to include(completed_gen)
      expect(AudioGeneration.completed).not_to include(pending_gen)
    end
  end
  
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:audio_generation)).to be_valid
    end
    
    it 'creates completed generation with audio_url' do
      gen = create(:audio_generation, :completed)
      expect(gen.audio_url).to be_present
      expect(gen.status).to eq('completed')
    end
  end
end
