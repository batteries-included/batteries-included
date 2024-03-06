import 'phoenix_html';
import { Socket } from 'phoenix';
import { LiveSocket, ViewHook } from 'phoenix_live_view';
import { IFrameHook } from './iframe';
import { ChartHook } from './chart';
import { ResourceLogsModalHook } from './resource-logs-modal';
import { TooltipHook } from '../../../common_ui/assets/js/tooltip';
import '../../../common_ui/assets/js/shared';

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  ?.getAttribute('content');

const hooks: { [name: string]: Partial<ViewHook> } = {
  IFrame: IFrameHook,
  Chart: ChartHook,
  Tooltip: TooltipHook,
  ResourceLogsModal: ResourceLogsModalHook,
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
