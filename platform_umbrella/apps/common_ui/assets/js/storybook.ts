import { TooltipHook } from './tooltip';

(function () {
  window.storybook = {
    Hooks: { Tooltip: TooltipHook },
    LiveSocketOptions: {},
  };
})();
