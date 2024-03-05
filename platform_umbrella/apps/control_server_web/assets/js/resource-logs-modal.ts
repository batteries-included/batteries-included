import { ViewHook } from 'phoenix_live_view';

export const ResourceLogsModalHook: Partial<ViewHook> = {
  mounted() {
    const el = this.el;
    const anchor = el.querySelector('#anchor');

    if (anchor) {
      requestAnimationFrame(() => {
        anchor.scrollIntoView();
      });
    }
  },
};
