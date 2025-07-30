import 'phoenix_html';
import { Socket } from 'phoenix';
import { LiveSocket, ViewHook } from 'phoenix_live_view';
import { IFrameHook } from './iframe';
import { ResourceLogsModalHook } from './resource-logs-modal';
import { ChartHook } from '../../../common_ui/assets/js/chart';
import { ClipboardHook } from '../../../common_ui/assets/js/clipboard';
import { RangeHook } from '../../../common_ui/assets/js/range';
import { TooltipHook } from '../../../common_ui/assets/js/tooltip';
import '../../../common_ui/assets/js/shared';
import ObjectDisplayHook from './object-display';

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  ?.getAttribute('content');

const hooks: { [name: string]: Partial<ViewHook> } = {
  IFrame: IFrameHook,
  Chart: ChartHook,
  Clipboard: ClipboardHook,
  Range: RangeHook,
  Tooltip: TooltipHook,
  ResourceLogsModal: ResourceLogsModalHook,
  ObjectDisplay: ObjectDisplayHook,
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
