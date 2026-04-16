// LibraryFinder - Main JavaScript

/**
 * Render library search results to the page
 * @param {Array} libraries - Array of library objects from Google Places API
 */
function renderResults(libraries) {
  const resultsList = document.getElementById('results-list');
  resultsList.innerHTML = '';
  
  if (!libraries || libraries.length === 0) {
    resultsList.innerHTML = `
      <div class="col-span-full text-center py-8">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mx-auto text-gray-300 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <p class="text-gray-500 text-lg">No libraries found. Try a different search.</p>
      </div>
    `;
    return;
  }

  libraries.forEach((lib, index) => {
    // Generate website link
    const website = lib.website || `https://www.google.com/search?q=${encodeURIComponent(lib.name + ' ' + lib.city + ' ' + lib.state)}`;
    
    // Format address
    const formattedAddress = `${lib.address || ''}, ${lib.city}, ${lib.state} ${lib.zip_code}`.replace(/^, /, '');
    
    // Create library card
    const card = document.createElement('div');
    card.className = 'bg-gray-50 p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow duration-200 border border-gray-100';
    card.innerHTML = `
      <div class="flex justify-between items-start mb-3">
        <h4 class="text-lg font-semibold text-gray-800 flex-1">${lib.name}</h4>
      </div>
      
      <p class="text-sm text-gray-600 mb-3 flex items-start gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mt-0.5 text-gray-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        <span>${formattedAddress}</span>
      </p>
      
      ${lib.phone ? `
        <p class="text-sm text-gray-600 mb-3 flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
          </svg>
          <span>${lib.phone}</span>
        </p>
      ` : ''}
      
      <a href="${website}" target="_blank" rel="noopener noreferrer" 
         class="inline-flex items-center gap-2 text-blue-600 hover:text-blue-700 font-medium text-sm transition-colors duration-200">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
        </svg>
        Visit Library Website
      </a>
    `;
    
    resultsList.appendChild(card);
    
    // Add animation delay for staggered effect
    setTimeout(() => {
      card.style.opacity = '0';
      card.style.transform = 'translateY(20px)';
      requestAnimationFrame(() => {
        card.style.transition = 'all 0.3s ease-out';
        card.style.opacity = '1';
        card.style.transform = 'translateY(0)';
      });
    }, index * 50);
  });
}

/**
 * Handle form submission and search for libraries
 */
const form = document.getElementById('search-form');
form.addEventListener('submit', (e) => {
  e.preventDefault();

  const city = document.getElementById('city-input').value.trim();
  const state = document.getElementById('state-input').value.trim();
  const zip = document.getElementById('zip-input').value.trim();

  // Validation
  if (!city && !state && !zip) {
    alert("Please enter at least one search parameter (city, state, or ZIP code).");
    return;
  }

  // Build API URL
  const params = new URLSearchParams();
  if (city) params.append('city', city);
  if (state) params.append('state', state);
  if (zip) params.append('zip', zip);

  const apiBaseUrl = window.APP_CONFIG?.apiUrl;
  if (!apiBaseUrl) {
    alert('API URL is not configured. Please set window.APP_CONFIG.apiUrl in index.html.');
    return;
  }

  const apiUrl = `${apiBaseUrl}?${params.toString()}`;
  
  // Show loading indicator
  const loading = document.getElementById('loading-message');
  const resultsList = document.getElementById('results-list');
  loading.classList.remove('hidden');
  resultsList.innerHTML = '';

  // Fetch from API
  fetch(apiUrl, { mode: 'cors' })
    .then(async response => {
      const text = await response.text();
      let data;
      try {
        data = JSON.parse(text);
      } catch (parseError) {
        throw new Error(`Invalid JSON response: ${text}`);
      }

      if (!response.ok) {
        const errorMessage = data?.error || data?.Message || response.statusText || 'Request failed';
        throw new Error(errorMessage);
      }

      return data;
    })
    .then(data => {
      loading.classList.add('hidden');
      
      if (data.success) {
        renderResults(data.libraries);
      } else {
        resultsList.innerHTML = `
          <div class="col-span-full text-center py-8">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mx-auto text-red-300 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p class="text-red-500 text-lg font-semibold">Search Error</p>
            <p class="text-gray-600 text-sm mt-2">${data.error || 'Unknown error'}</p>
          </div>
        `;
      }
    })
    .catch(error => {
      loading.classList.add('hidden');
      resultsList.innerHTML = `
        <div class="col-span-full text-center py-8">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mx-auto text-red-300 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <p class="text-red-500 text-lg font-semibold">Network Error</p>
          <p class="text-gray-600 text-sm mt-2">${error.message || 'Please try again later.'}</p>
        </div>
      `;
      console.error('Fetch error:', error);
    });
});

// Smooth scroll for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', function (e) {
    e.preventDefault();
    const target = document.querySelector(this.getAttribute('href'));
    if (target) {
      target.scrollIntoView({
        behavior: 'smooth',
        block: 'start'
      });
    }
  });
});

// Add focus states for accessibility
document.querySelectorAll('input, button, a').forEach(element => {
  element.addEventListener('focus', function() {
    this.classList.add('ring-2', 'ring-blue-500', 'ring-opacity-50');
  });
  
  element.addEventListener('blur', function() {
    this.classList.remove('ring-2', 'ring-blue-500', 'ring-opacity-50');
  });
});

console.log('LibraryFinder initialized ✓');
