import 'phoenix_html';
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';
import Alpine from 'alpinejs';
import { IFrameHook } from './iframe';
import { ChartHook } from './chart';
import { TooltipHook } from './tooltip';
import { ResourceLogsModalHook } from './resource-logs-modal';
import '../../../common_ui/assets/js/shared';

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');

const liveSocket = new LiveSocket('/live', Socket, {
  params: { _csrf_token: csrfToken },
  hooks: {
    IFrame: IFrameHook,
    Chart: ChartHook,
    Tooltip: TooltipHook,
    ResourceLogsModal: ResourceLogsModalHook,
  },
  dom: {
    // make LiveView work nicely with AlpineJS
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to);
      }
      return true;
    },
  },
});

Alpine.start();
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
window.Alpine = Alpine;
