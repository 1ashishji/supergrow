// API Configuration
const API_BASE_URL = window.location.origin;
const API_ENDPOINTS = {
    generateVoice: `${API_BASE_URL}/api/v1/generate_voice`,
    audioGenerations: `${API_BASE_URL}/api/v1/audio_generations`
};

// DOM Elements
const voiceForm = document.getElementById('voiceForm');
const textInput = document.getElementById('textInput');
const voiceSelect = document.getElementById('voiceSelect');
const generateBtn = document.getElementById('generateBtn');
const charCount = document.getElementById('charCount');
const statusDisplay = document.getElementById('statusDisplay');
const statusMessage = document.getElementById('statusMessage');
const audioPlayer = document.getElementById('audioPlayer');
const audioElement = document.getElementById('audioElement');
const downloadBtn = document.getElementById('downloadBtn');
const historyContainer = document.getElementById('historyContainer');
const refreshBtn = document.getElementById('refreshBtn');

// State
let currentGenerationId = null;
let pollingInterval = null;

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    loadHistory();
    setupEventListeners();
});

// Event Listeners
function setupEventListeners() {
    // Character counter
    textInput.addEventListener('input', updateCharCount);
    
    // Form submission
    voiceForm.addEventListener('submit', handleFormSubmit);
    
    // Refresh button
    refreshBtn.addEventListener('click', loadHistory);
}

function updateCharCount() {
    const count = textInput.value.length;
    charCount.textContent = count;
    
    if (count > 4500) {
        charCount.style.color = 'var(--warning)';
    } else {
        charCount.style.color = 'var(--text-secondary)';
    }
}

async function handleFormSubmit(e) {
    e.preventDefault();
    
    const text = textInput.value.trim();
    if (!text) {
        showStatus('Please enter some text', 'failed');
        return;
    }
    
    // Disable form
    setFormLoading(true);
    hideAudioPlayer();
    
    try {
        const response = await fetch(API_ENDPOINTS.generateVoice, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                audio_generation: {
                    text: text,
                    voice_id: voiceSelect.value
                }
            })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            currentGenerationId = data.id;
            showStatus('Voice generation started...', 'pending');
            startPolling(data.id);
        } else {
            showStatus(data.errors ? data.errors.join(', ') : 'Generation failed', 'failed');
            setFormLoading(false);
        }
    } catch (error) {
        console.error('Error:', error);
        showStatus('Network error. Please try again.', 'failed');
        setFormLoading(false);
    }
}

function setFormLoading(loading) {
    generateBtn.disabled = loading;
    textInput.disabled = loading;
    voiceSelect.disabled = loading;
    
    if (loading) {
        generateBtn.classList.add('loading');
    } else {
        generateBtn.classList.remove('loading');
    }
}

function showStatus(message, status) {
    statusMessage.textContent = message;
    statusDisplay.className = `status-display ${status}`;
    statusDisplay.classList.remove('hidden');
}

function hideStatus() {
    statusDisplay.classList.add('hidden');
}

function showAudioPlayer(audioUrl) {
    audioElement.src = audioUrl;
    downloadBtn.href = audioUrl;
    audioPlayer.classList.remove('hidden');
}

function hideAudioPlayer() {
    audioPlayer.classList.add('hidden');
    audioElement.src = '';
}

// Polling for generation status
function startPolling(generationId) {
    // Clear any existing polling
    if (pollingInterval) {
        clearInterval(pollingInterval);
    }
    
    // Poll every 2 seconds
    pollingInterval = setInterval(() => {
        checkGenerationStatus(generationId);
    }, 2000);
    
    // Also check immediately
    checkGenerationStatus(generationId);
}

function stopPolling() {
    if (pollingInterval) {
        clearInterval(pollingInterval);
        pollingInterval = null;
    }
}

async function checkGenerationStatus(generationId) {
    try {
        const response = await fetch(`${API_ENDPOINTS.audioGenerations}/${generationId}`);
        const data = await response.json();
        
        if (response.ok) {
            updateGenerationStatus(data);
        }
    } catch (error) {
        console.error('Polling error:', error);
    }
}

function updateGenerationStatus(data) {
    switch (data.status) {
        case 'pending':
            showStatus('Waiting in queue...', 'pending');
            break;
            
        case 'processing':
            showStatus('Generating voice audio...', 'processing');
            break;
            
        case 'completed':
            stopPolling();
            showStatus('Voice generated successfully!', 'completed');
            showAudioPlayer(data.audio_url);
            setFormLoading(false);
            loadHistory(); // Refresh history
            
            // Auto-hide status after 3 seconds
            setTimeout(() => {
                hideStatus();
            }, 3000);
            break;
            
        case 'failed':
            stopPolling();
            showStatus(data.error_message || 'Generation failed', 'failed');
            setFormLoading(false);
            loadHistory(); // Refresh history
            break;
    }
}

// History Management
async function loadHistory() {
    historyContainer.innerHTML = '<div class="loading-spinner">Loading history...</div>';
    
    try {
        const response = await fetch(`${API_ENDPOINTS.audioGenerations}?per_page=20`);
        const data = await response.json();
        
        if (response.ok && data.audio_generations) {
            renderHistory(data.audio_generations);
        } else {
            historyContainer.innerHTML = '<div class="empty-state">Failed to load history</div>';
        }
    } catch (error) {
        console.error('Error loading history:', error);
        historyContainer.innerHTML = '<div class="empty-state">Failed to load history</div>';
    }
}

function renderHistory(generations) {
    if (generations.length === 0) {
        historyContainer.innerHTML = `
            <div class="empty-state">
                <svg width="64" height="64" viewBox="0 0 64 64" fill="currentColor" opacity="0.3">
                    <path d="M32 8C18.7 8 8 18.7 8 32s10.7 24 24 24 24-10.7 24-24S45.3 8 32 8zm0 4c11.1 0 20 8.9 20 20s-8.9 20-20 20-20-8.9-20-20 8.9-20 20-20z"/>
                    <path d="M30 20h4v16h-4zM30 40h4v4h-4z"/>
                </svg>
                <p>No voice generations yet</p>
                <p style="font-size: 0.9rem; margin-top: 0.5rem;">Start by entering text above</p>
            </div>
        `;
        return;
    }
    
    historyContainer.innerHTML = generations.map(gen => createHistoryItem(gen)).join('');
}

function createHistoryItem(generation) {
    const date = new Date(generation.created_at);
    const formattedDate = date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
    
    const truncatedText = generation.text.length > 150 
        ? generation.text.substring(0, 150) + '...' 
        : generation.text;
    
    const audioPlayer = generation.status === 'completed' && generation.audio_url
        ? `<div class="history-item-audio">
                <audio controls src="${generation.audio_url}"></audio>
           </div>`
        : '';
    
    const errorMessage = generation.status === 'failed' && generation.error_message
        ? `<div style="color: var(--error); font-size: 0.85rem; margin-top: 0.5rem;">
                ${generation.error_message}
           </div>`
        : '';
    
    return `
        <div class="history-item">
            <div class="history-item-header">
                <div class="history-item-text">${escapeHtml(truncatedText)}</div>
                <span class="history-item-status ${generation.status}">${generation.status}</span>
            </div>
            <div class="history-item-meta">
                <span>${formattedDate}</span>
                ${generation.duration ? `<span>${generation.duration.toFixed(1)}s</span>` : ''}
            </div>
            ${audioPlayer}
            ${errorMessage}
        </div>
    `;
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Auto-refresh history every 30 seconds
setInterval(() => {
    if (!pollingInterval) { // Only refresh if not actively generating
        loadHistory();
    }
}, 30000);
