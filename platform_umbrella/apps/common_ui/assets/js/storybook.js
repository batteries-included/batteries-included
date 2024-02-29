import Alpine from 'alpinejs';

window.Alpine = Alpine;

document.addEventListener('DOMContentLoaded', () => {
  window.Alpine.start();
});

(function () {
  window.storybook = {
    Hooks: {},
    LiveSocketOptions: {
      dom: {
        onBeforeElUpdated(from, to) {
          if (from._x_dataStack) {
            window.Alpine.clone(from, to);
          }
        },
      },
    },
  };
})();
