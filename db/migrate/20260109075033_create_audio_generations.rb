class CreateAudioGenerations < ActiveRecord::Migration[7.0]
  def change
    create_table :audio_generations do |t|
      t.text :text
      t.string :status
      t.string :audio_url
      t.string :cloudinary_public_id
      t.text :error_message
      t.string :voice_id
      t.float :duration
      t.integer :file_size

      t.timestamps
    end
    
    add_index :audio_generations, :status
    add_index :audio_generations, :created_at
  end
end
