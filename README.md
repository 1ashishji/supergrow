# Voice Generator - AI Text-to-Speech Application

A Ruby on Rails application that converts text to natural-sounding speech using the ElevenLabs API. Features include background job processing, cloud storage, and a modern web interface.

## Features

- **Text-to-Speech Generation**: Convert text to high-quality audio using ElevenLabs AI voices (Turbo v2.5 model)
- **Multiple Voices**: Choose from various voice options (Rachel, Domi, Bella, Antoni, etc.)
- **Background Processing**: Asynchronous audio generation using Sidekiq
- **Cloud Storage**: Audio files stored on Cloudinary
- **Modern UI**: Premium dark-mode interface with real-time status updates
- **Generation History**: Track and replay previously generated audio
- **RESTful API**: JSON API for programmatic access
- **Comprehensive Tests**: Full RSpec test suite with 100% pass rate (29 tests)

## Tech Stack

- **Backend**: Ruby 3.0.6, Rails 7.0.10
- **Database**: MySQL 8.0
- **Background Jobs**: Sidekiq (requires Redis)
- **External APIs**: ElevenLabs (text-to-speech), Cloudinary (storage)
- **Testing**: RSpec, FactoryBot, WebMock, Shoulda Matchers
- **Frontend**: Vanilla JavaScript, HTML5, CSS3

## Prerequisites

- Ruby 3.0.6 (via RVM)
- MySQL 8.0+
- Redis (for Sidekiq background jobs)
- ElevenLabs API key
- Cloudinary account (free tier available)

## Installation

### 1. Clone and Setup

```bash
cd /var/www/html/ror/voice_generator
bundle install
```

### 2. Configure Environment Variables

The `.env` file has been created with your credentials. Update `CLOUDINARY_CLOUD_NAME` if needed:

```bash
# .env
ELEVENLABS_API_KEY=sk_aebafc102ed039cf1352b2f45c21ccdef3152a2f5ce6c662
CLOUDINARY_CLOUD_NAME=your_cloud_name  # Update this
CLOUDINARY_API_KEY=791299454532757
CLOUDINARY_API_SECRET=3lqYuoLeIBWcSYnKiFzsWLdAbjk
REDIS_URL=redis://localhost:6379/0
```

### 3. Database Setup

```bash
# Database is already created and migrated
# If you need to reset:
rails db:drop db:create db:migrate
```

### 4. Start Redis (Required for Sidekiq)

```bash
# Install Redis if not already installed
sudo apt-get install redis-server

# Start Redis
redis-server
```

## Running the Application

### Start Rails Server

```bash
bash -c "source ~/.rvm/scripts/rvm && rvm use 3.0.6 && rails server -p 3000"
```

### Start Sidekiq (in a separate terminal)

```bash
bash -c "source ~/.rvm/scripts/rvm && rvm use 3.0.6 && bundle exec sidekiq"
```

### Access the Application

- **Web Interface**: http://localhost:3000
- **API Endpoint**: http://localhost:3000/api/v1/

## API Documentation

### Generate Voice

**POST** `/api/v1/generate_voice`

```json
{
  "audio_generation": {
    "text": "Hello, this is a test of the voice generation system.",
    "voice_id": "21m00Tcm4TlvDq8ikWAM"
  }
}
```

**Response:**
```json
{
  "id": 1,
  "status": "pending",
  "text": "Hello, this is a test...",
  "created_at": "2026-01-09T07:50:33.000Z"
}
```

### List Generations

**GET** `/api/v1/audio_generations?page=1&per_page=20&status=completed`

**Response:**
```json
{
  "audio_generations": [
    {
      "id": 1,
      "text": "Hello, this is a test...",
      "status": "completed",
      "audio_url": "https://res.cloudinary.com/...",
      "voice_id": "21m00Tcm4TlvDq8ikWAM",
      "duration": 5.2,
      "file_size": 82400,
      "created_at": "2026-01-09T07:50:33.000Z"
    }
  ],
  "page": 1,
  "per_page": 20
}
```

### Get Single Generation

**GET** `/api/v1/audio_generations/:id`

## Available Voices

- `21m00Tcm4TlvDq8ikWAM` - Rachel (Female, American)
- `AZnzlk1XvdvUeBnXmlld` - Domi (Female, American)
- `EXAVITQu4vr4xnSDxMaL` - Bella (Female, American)
- `ErXwobaYiN019PkySvjV` - Antoni (Male, American)
- `MF3mGyEYCl7XYWbV9V6O` - Elli (Female, American)
- `TxGEqnHWrfWFTfGW9XjX` - Josh (Male, American)

## Testing

### Run All Tests

```bash
bash -c "source ~/.rvm/scripts/rvm && rvm use 3.0.6 && bundle exec rspec"
```

### Run Specific Test Files

```bash
# Model tests
bundle exec rspec spec/models/

# API tests
bundle exec rspec spec/requests/

# Service tests
bundle exec rspec spec/services/

# Job tests
bundle exec rspec spec/jobs/
```

## Architecture

### Data Model

**AudioGeneration**
- `text` (text) - Input text for speech generation
- `status` (string) - pending, processing, completed, failed
- `audio_url` (string) - URL of generated audio file
- `cloudinary_public_id` (string) - Cloudinary identifier
- `error_message` (text) - Error details if failed
- `voice_id` (string) - ElevenLabs voice ID
- `duration` (float) - Audio duration in seconds
- `file_size` (integer) - File size in bytes

### Services

- **ElevenLabsService**: Handles API communication with ElevenLabs
- **CloudinaryService**: Manages audio file uploads to Cloudinary

### Background Jobs

- **GenerateAudioJob**: Processes audio generation asynchronously
  - Calls ElevenLabsService to generate audio
  - Uploads to Cloudinary via CloudinaryService
  - Updates AudioGeneration record with results
  - Retry logic: 3 attempts with exponential backoff

## Project Structure

```
voice_generator/
├── app/
│   ├── controllers/
│   │   └── api/v1/
│   │       └── audio_generations_controller.rb
│   ├── jobs/
│   │   └── generate_audio_job.rb
│   ├── models/
│   │   └── audio_generation.rb
│   └── services/
│       ├── eleven_labs_service.rb
│       └── cloudinary_service.rb
├── config/
│   ├── initializers/
│   │   ├── cloudinary.rb
│   │   └── cors.rb
│   └── routes.rb
├── public/
│   ├── index.html
│   ├── css/style.css
│   └── js/app.js
└── spec/
    ├── factories/
    ├── models/
    ├── requests/
    ├── services/
    └── jobs/
```

## Troubleshooting

### Redis Connection Error

If Sidekiq can't connect to Redis:
```bash
# Check if Redis is running
redis-cli ping
# Should return: PONG

# Start Redis if not running
redis-server
```

### Database Connection Error

Verify MySQL credentials in `config/database.yml`:
```yaml
username: root
password: ztech44
host: localhost
```

### ElevenLabs API Errors

- Check API key is valid in `.env`
- Verify account has available credits
- Check rate limits (free tier: 10,000 characters/month)

### Cloudinary Upload Errors

- Verify cloud name, API key, and secret in `.env`
- Check free tier limits (25GB storage, 25GB bandwidth/month)

## License

This project is open source and available under the MIT License.
