import 'phoenix_html';
import { Socket } from 'phoenix';
import { LiveSocket, ViewHook } from 'phoenix_live_view';
import { ChartHook } from '../../../common_ui/assets/js/chart';
import { ClipboardHook } from '../../../common_ui/assets/js/clipboard';
import { TooltipHook } from '../../../common_ui/assets/js/tooltip';
import '../../../common_ui/assets/js/shared';

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  ?.getAttribute('content');

const hooks: { [name: string]: Partial<ViewHook> } = {
  Chart: ChartHook,
  Clipboard: ClipboardHook,
  Tooltip: TooltipHook,
};

const liveSocket = new LiveSocket('/live', Socket, {
  params: { _csrf_token: csrfToken },
  hooks,
});

liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
