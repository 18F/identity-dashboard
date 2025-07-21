document.addEventListener('DOMContentLoaded', function() {
  const year = '2025';
  const date = '2025-06-14';
  const resultsDiv = document.getElementById('report-results');
  const section = document.getElementById('daily-auths-section');
  const serviceProviderId = section.dataset.serviceProviderId;
    
  // Make the request to stream_daily_auths_report
  const url = `/analytics/service_providers/${serviceProviderId}/stream_daily_auths_report?year=${year}&date=${date}`;
  fetch(url)
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then(data => {      
      resultsDiv.innerHTML = `<pre style="background-color: #f5f5f5; padding: 10px; border-radius: 5px; overflow-x: auto;">${JSON.stringify(data, null, 2)}</pre>`;
    })
    .catch(error => {
      resultsDiv.innerHTML = `<p style="color: red;">Error: ${error.message}</p>`;
    });
});