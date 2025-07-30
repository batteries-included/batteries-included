import { ViewHook } from 'phoenix_live_view';

const ObjectDisplayHook: ViewHook = {
  updated() {
    // Find the last column (div with object-display-column class)
    let lastColumn = this.el.querySelector(
      '.object-display-column:last-of-type'
    );

    if (lastColumn) {
      // Get the scroll container (this.el should be the flex container with overflow-x-auto)
      const scrollContainer = this.el;

      // Calculate the position to scroll to
      const containerRect = scrollContainer.getBoundingClientRect();
      const columnRect = lastColumn.getBoundingClientRect();

      // Calculate the scroll position to center the last column
      const targetScrollLeft =
        lastColumn.offsetLeft - containerRect.width / 2 + columnRect.width / 2;

      // Scroll the container horizontally
      scrollContainer.scrollTo({
        left: Math.max(0, targetScrollLeft),
        behavior: 'smooth',
      });
    }
  },
};

export default ObjectDisplayHook;
