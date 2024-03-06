import { ViewHook } from 'phoenix_live_view';
import tippy from 'tippy.js';

export interface TooltipHookInterface extends ViewHook {
  tippyInstances: any;
  createTippy(): void;
}

export const TooltipHook = {
  mounted() {
    this.createTippy();
  },

  updated() {
    if (this.tippyInstances != null) {
      this.tippyInstances.forEach((element: any) => {
        element.destroy();
      });
      this.tippyInstances = null;
    }
    this.createTippy();
  },

  createTippy() {
    const target = '#' + this.el.dataset.target;
    const content = this.el.innerHTML;
    const tippyOptions = JSON.parse(this.el.dataset.tippyOptions);
    const defaultOptions = {
      content: content,
      allowHTML: true,
    };

    this.tippyInstances = tippy(target, { ...defaultOptions, ...tippyOptions });
  },
} as TooltipHookInterface;
