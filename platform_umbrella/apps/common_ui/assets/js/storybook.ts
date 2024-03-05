import Alpine, { XAttributes } from 'alpinejs';

window.Alpine = Alpine;

document.addEventListener('DOMContentLoaded', () => {
  window.Alpine.start();
});

(function () {
  window.storybook = {
    Hooks: {},
    LiveSocketOptions: {
      dom: {
        // make LiveView work nicely with AlpineJS
        onBeforeElUpdated(from, to) {
          const stack = (from as HTMLElement & XAttributes)._x_dataStack;

          if (stack) {
            Alpine.clone(from, to);
          }

          return true;
        },
      },
    },
  };
})();
