import Chart from 'chart.js/auto';

function initCharts() {
  document.querySelectorAll('.analytics-chart').forEach((canvas) => {
    const config = JSON.parse(canvas.dataset.config);
    new Chart(canvas.getContext('2d'), config);
  });
}

// Run when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initCharts);
} else {
  initCharts();
}