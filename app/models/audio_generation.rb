class AudioGeneration < ApplicationRecord
  STATUSES = %w[pending processing completed failed].freeze
  MAX_TEXT_LENGTH = 5000
  
  # Validations
  validates :text, presence: true, length: { maximum: MAX_TEXT_LENGTH }
  validates :status, presence: true, inclusion: { in: STATUSES }
  
  # Callbacks
  before_validation :set_default_status, on: :create
  before_validation :set_default_voice_id, on: :create
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :pending, -> { where(status: 'pending') }
  scope :processing, -> { where(status: 'processing') }
  
  private
  
  def set_default_status
    self.status ||= 'pending'
  end
  
  def set_default_voice_id
    # Rachel - a popular ElevenLabs voice
    self.voice_id ||= '21m00Tcm4TlvDq8ikWAM'
  end
end
