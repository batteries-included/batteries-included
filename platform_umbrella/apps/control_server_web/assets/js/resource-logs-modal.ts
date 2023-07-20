import { ViewHook } from 'phoenix_live_view';

const ResourceLogsModal: Partial<ViewHook> = {
  mounted() {
    const el = (this as ViewHook).el;
    const anchor = el.querySelector<HTMLDivElement>('#anchor');

    if (!anchor) return;

    requestAnimationFrame(() => {
      // scrollIntoViewIfNeeded is not supported in Safari
      // @ts-ignore
      anchor.scrollIntoViewIfNeeded() || anchor.scrollIntoView();
    });
  },
};

export { ResourceLogsModal };
