import { ChartHook } from './chart';
import { RangeHook } from './range';
import { TooltipHook } from './tooltip';

(function () {
  window.storybook = {
    LiveSocketOptions: {},
    Hooks: {
      Chart: ChartHook,
      Range: RangeHook,
      Tooltip: TooltipHook,
    },
  };
})();
