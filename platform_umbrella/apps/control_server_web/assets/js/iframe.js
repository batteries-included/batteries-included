/* eslint-disable no-param-reassign */
import { debounce } from 'lodash/debounce';

const maxHeight = (element) =>
  element
    ? Math.max(
        element.scrollHeight || 0,
        element.offsetHeight || 0,
        element.clientHeight || 0
      )
    : 0;

const boundingHeight = (element) =>
  element ? element.getBoundingClientRect().height : 0;

const resize = (element) => {
  if (element && element.contentWindow) {
    const iframeDocument = element.contentWindow.document;
    const iframeBody = iframeDocument.body;
    const iframeDocumentElement = iframeDocument.documentElement;

    const height = Math.max(
      maxHeight(iframeBody),
      maxHeight(iframeDocumentElement),
      boundingHeight(element.parentNode)
    );
    element.style.height = `${height}px`;
  }
};

export default {
  mounted() {
    const doResize = debounce(() => resize(this.el), 500, {
      leading: true,
      trailing: false,
    });
    this.el.addEventListener('load', doResize);
    window.addEventListener('resize', doResize);
    setInterval(doResize, 1000);
  },
};
