document.addEventListener('DOMContentLoaded', () => {
    const generateForm = document.getElementById('generate-form');
    const generateBtn = document.getElementById('generate-btn');
    const generationsList = document.getElementById('generations-list');
    const refreshBtn = document.getElementById('refresh-btn');
    const textInput = document.getElementById('text-input');

    // Handle Form Submission
    if (generateForm) {
        generateForm.addEventListener('submit', async (e) => {
            e.preventDefault();

            const text = textInput.value.trim();
            const voiceId = document.getElementById('voice-select').value;

            if (!text) return;

            setLoading(true);

            try {
                const response = await fetch('/api/v1/generate_voice', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({
                        audio_generation: {
                            text: text,
                            voice_id: voiceId
                        }
                    })
                });

                if (!response.ok) throw new Error('Generation failed');

                const data = await response.json();

                // Add new item to the top of the list
                addNewItem(data);

                // Clear input
                textInput.value = '';

                // Start polling for this item
                pollStatus(data.id);

            } catch (error) {
                console.error('Error:', error);
                alert('Failed to start audio generation. Please try again.');
            } finally {
                setLoading(false);
            }
        });
    }

    // Handle Refresh Button
    if (refreshBtn) {
        refreshBtn.addEventListener('click', () => {
            window.location.reload();
        });
    }

    // Poll for status updates
    const activePolls = new Set();

    function pollStatus(id) {
        if (activePolls.has(id)) return;
        activePolls.add(id);

        const interval = setInterval(async () => {
            try {
                const response = await fetch(`/api/v1/audio_generations/${id}`);
                if (!response.ok) return;

                const data = await response.json();
                const card = document.querySelector(`article[data-id="${id}"]`);

                if (card && data.status !== 'processing') {
                    // Status changed, reload the page or update the card
                    // For simplicity in this version, we'll reload to get the full rendered partial
                    // In a more complex app, we'd request the partial via HTML format

                    clearInterval(interval);
                    activePolls.delete(id);

                    // Flash the card to indicate update (visual feedback)
                    card.style.opacity = '0.5';
                    setTimeout(() => window.location.reload(), 300);
                }
            } catch (error) {
                console.error('Polling error:', error);
            }
        }, 2000); // Poll every 2 seconds
    }

    // Check for any existing processing items on load
    document.querySelectorAll('article[data-status="processing"]').forEach(card => {
        const id = card.dataset.id;
        if (id) pollStatus(id);
    });

    // Helpers
    function setLoading(isLoading) {
        if (generateBtn) {
            generateBtn.disabled = isLoading;
            const span = generateBtn.querySelector('span');
            if (span) span.textContent = isLoading ? 'Starting...' : 'Generate Voice';
        }
    }

    function addNewItem(data) {
        // Reloading is the simplest way to get the server-rendered partial correct
        // In a full SPA we would client-side render the template
        window.location.reload();
    }
});
