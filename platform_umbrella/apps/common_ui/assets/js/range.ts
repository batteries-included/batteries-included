import { ViewHook } from 'phoenix_live_view';

export const RangeHook = {
  mounted() {
    this.inputEl = this.getChildEl('input');
    this.progressEl = this.getChildEl('progress');
    this.valueEl = this.getChildEl('value');

    this.setPosition();
    this.inputEl.addEventListener('input', () => this.setPosition());
  },
  updated() {
    this.setPosition();
  },
  destroyed() {
    this.inputEl.removeEventListener('input', () => this.setPosition());
  },
  getChildEl(type) {
    return this.el.querySelector(`#${this.el.id}-${type}`);
  },
  setPosition() {
    const thumbSize = 32;

    const rangeWidth = this.inputEl.offsetWidth;
    const rangeCenter = rangeWidth / 2;
    const percent =
      (this.inputEl.value - this.inputEl.min) /
      (this.inputEl.max - this.inputEl.min);

    const currentPosition = percent * rangeWidth;
    const percentFromCenter = (currentPosition - rangeCenter) / rangeCenter;
    const finalPosition = currentPosition - percentFromCenter * (thumbSize / 2);

    this.progressEl.style.width = `${finalPosition}px`;

    if (this.valueEl) {
      this.valueEl.style.left = `${finalPosition - thumbSize / 2}px`;
      this.valueEl.innerHTML = this.inputEl.value;
    }
  },
} as ViewHook;
