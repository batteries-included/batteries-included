import { RangeHook } from './range';
import { TooltipHook } from './tooltip';

(function () {
  window.storybook = {
    LiveSocketOptions: {},
    Hooks: {
      Range: RangeHook,
      Tooltip: TooltipHook,
    },
  };
})();
