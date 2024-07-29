import { ViewHook } from 'phoenix_live_view';

export interface ClipboardHookInterface extends ViewHook {
  contents: string;
  clipboardIcon: HTMLElement;
  checkmarkIcon: HTMLElement;
  copyToClipboard(): Promise<void>;
  showCheck(): void;
  hideCheck(): void;
}

export const ClipboardHook = {
  mounted() {
    this.contents = document.querySelector(this.el.dataset.to).innerHTML;
    this.clipboardIcon = document.querySelector(`#${this.el.id}-icon`);
    this.checkmarkIcon = document.querySelector(`#${this.el.id}-check`);

    this.el.addEventListener('click', (event) => this.copyToClipboard(event));
  },
  destroyed() {
    this.el.removeEventListener('click', (event) =>
      this.copyToClipboard(event)
    );
  },
  async copyToClipboard(event) {
    event.preventDefault();

    await navigator.clipboard.writeText(this.contents);

    this.showCheck();
    setTimeout(() => this.hideCheck(), 2000);
  },
  showCheck() {
    this.clipboardIcon.classList.add('hidden');
    this.checkmarkIcon.classList.remove('hidden');
  },
  hideCheck() {
    this.clipboardIcon.classList.remove('hidden');
    this.checkmarkIcon.classList.add('hidden');
  },
} as ClipboardHookInterface;
