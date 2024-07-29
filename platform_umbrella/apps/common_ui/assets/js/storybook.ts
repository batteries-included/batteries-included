import { ChartHook } from './chart';
import { ClipboardHook } from './clipboard';
import { RangeHook } from './range';
import { TooltipHook } from './tooltip';

(function () {
  window.storybook = {
    LiveSocketOptions: {},
    Hooks: {
      Chart: ChartHook,
      Clipboard: ClipboardHook,
      Range: RangeHook,
      Tooltip: TooltipHook,
    },
  };
})();
