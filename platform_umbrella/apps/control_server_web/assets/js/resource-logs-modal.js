export const ResourceLogsModalHook = {
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
