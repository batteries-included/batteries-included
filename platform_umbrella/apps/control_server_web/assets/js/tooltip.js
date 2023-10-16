import tippy from 'tippy.js';

const Tooltip = {
  /** When mounted create the tippy.js tooltip. */
  mounted() {
    this.createTippy();
  },

  /** When updated remove any old tooltips and create new ones */
  updated() {
    if (this.tippyInstances != null) {
      this.tippyInstances.forEach((element) => {
        element.destroy();
      });
      this.tippyInstances = null;
    }
    this.createTippy();
  },

  /** The method to create tippy tooltips. */
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
};

export { Tooltip };
