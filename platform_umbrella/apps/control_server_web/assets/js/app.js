/* eslint no-underscore-dangle: 0 */
import '../css/app.css';

import 'phoenix_html';
import { Socket } from 'phoenix';
import topbar from 'topbar';
import { LiveSocket } from 'phoenix_live_view';
import Alpinejs from 'alpinejs';
import Sparkline from './sparkline';

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');
const liveSocket = new LiveSocket('/live', Socket, {
  dom: {
    onBeforeElUpdated(from, to) {
      if (from.__x) {
        Alpinejs.clone(from.__x, to);
      }
    },
  },
  hooks: { Sparkline },
  params: { _csrf_token: csrfToken },
});

// Show progress bar on live navigation and form submits
topbar.config({
  barColors: { 0: '#fc408b' },
  shadowColor: 'rgba(0, 0, 0, .3)',
});
window.addEventListener('phx:page-loading-start', () => topbar.show());
window.addEventListener('phx:page-loading-stop', () => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
