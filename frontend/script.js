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
    const website = lib.website || `https://www.google.com/search?q=${encodeURIComponent(lib.name + ' ' + lib.formatted_address)}`;
    
    // Create library card
    const card = document.createElement('div');
    card.className = 'bg-gray-50 p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow duration-200 border border-gray-100';
    card.innerHTML = `
      <div class="flex justify-between items-start mb-3">
        <h4 class="text-lg font-semibold text-gray-800 flex-1">${lib.name}</h4>
        ${lib.rating ? `
          <div class="flex items-center gap-1 ml-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
              <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
            </svg>
            <span class="text-sm font-medium text-gray-600">${lib.rating}</span>
          </div>
        ` : ''}
      </div>
      
      <p class="text-sm text-gray-600 mb-3 flex items-start gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mt-0.5 text-gray-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        <span>${lib.formatted_address || lib.vicinity || 'Address not available'}</span>
      </p>
      
      ${lib.opening_hours ? `
        <p class="text-sm mb-3 flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span class="${lib.opening_hours.open_now ? 'text-green-600 font-medium' : 'text-red-600 font-medium'}">
            ${lib.opening_hours.open_now ? 'Open Now' : 'Closed'}
          </span>
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

  // Build search query
  const query = `library in ${city} ${state} ${zip}`.trim();
  
  // Show loading indicator
  const loading = document.getElementById('loading-message');
  const resultsList = document.getElementById('results-list');
  loading.classList.remove('hidden');
  resultsList.innerHTML = '';

  // Check if Google Maps API is loaded
  if (typeof google === 'undefined' || !google.maps || !google.maps.places) {
    loading.classList.add('hidden');
    resultsList.innerHTML = `
      <div class="col-span-full text-center py-8 text-red-600">
        <p class="text-lg font-semibold">Google Maps API not loaded</p>
        <p class="text-sm mt-2">Please add your Google Maps API key to use the search feature.</p>
      </div>
    `;
    return;
  }

  // Perform search using Google Places API
  const service = new google.maps.places.PlacesService(document.createElement('div'));
  
  service.textSearch({ query }, (results, status) => {
    loading.classList.add('hidden');
    
    if (status === google.maps.places.PlacesServiceStatus.OK) {
      renderResults(results);
      
      // TODO: Send search analytics to backend API
      // Example:
      // fetch('/api/searches', {
      //   method: 'POST',
      //   headers: { 'Content-Type': 'application/json' },
      //   body: JSON.stringify({ city, state, zip, results_count: results.length })
      // });
      
    } else {
      resultsList.innerHTML = `
        <div class="col-span-full text-center py-8">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mx-auto text-red-300 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <p class="text-red-500 text-lg font-semibold">Search Error</p>
          <p class="text-gray-600 text-sm mt-2">Status: ${status}</p>
          <p class="text-gray-500 text-sm mt-1">Please try again or refine your search.</p>
        </div>
      `;
    }
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
