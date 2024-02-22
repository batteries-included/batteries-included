export const ResourceLogsModalHook = {
  mounted() {
    const el = this.el;
    const anchor = el.querySelector('#anchor');

    if (anchor) {
      requestAnimationFrame(() => {
        // scrollIntoViewIfNeeded is not supported in Safari
        anchor.scrollIntoViewIfNeeded() || anchor.scrollIntoView();
      });
    }
  },
};
