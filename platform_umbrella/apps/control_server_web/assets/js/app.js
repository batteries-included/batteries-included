/* eslint no-underscore-dangle: 0 */

import 'phoenix_html';
import { Socket } from 'phoenix';
import topbar from 'topbar';
import { LiveSocket } from 'phoenix_live_view';
import Alpine from 'alpinejs';

import IFrame from './iframe';
import Kratos from './kratos';

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');

const liveSocket = new LiveSocket('/live', Socket, {
  dom: {
    // make LiveView work nicely with AlpineJS
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to);
      }
    },
  },
  hooks: { IFrame, Kratos },
  params: { _csrf_token: csrfToken },
});

// Show progress bar on live navigation and form submits
const showBarDelay = 100;
topbar.config({
  barThickness: 5,
  barColors: {
    0: '#fc408b',
    '.3': '#247BA0',
    '1.0': '#36D399',
  },
  shadowBlur: 5,
  shadowColor: 'rgba(0, 0, 0, .3)',
});

Alpine.start();

let topBarScheduled;
window.addEventListener('phx:page-loading-start', () => {
  topBarScheduled =
    topBarScheduled || setTimeout(() => topbar.show(), showBarDelay);
});
window.addEventListener('phx:page-loading-stop', () => {
  clearTimeout(topBarScheduled);
  topBarScheduled = undefined;
  topbar.hide();
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
window.Alpine = Alpine;
