import topbar from 'topbar';

// Configure the look of the navigation progress bar
topbar.config({
  barColors: { 0: '#fc408b', '.3': '#247BA0', '1.0': '#36D399' },
  barThickness: 5,
  shadowColor: 'rgba(0, 0, 0, .3)',
  shadowBlur: 5,
});

// Show progress bar on live navigation and form submits
window.addEventListener('phx:page-loading-start', () => topbar.show(100));
window.addEventListener('phx:page-loading-stop', () => topbar.hide());
