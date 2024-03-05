import { LiveSocket, ViewHook } from 'phoenix_live_view';
import { Alpine } from 'alpinejs';

declare global {
  interface Window {
    liveSocket: LiveSocket;
    Alpine: Alpine;
    storybook: {
      Hooks: { [name: string]: Partial<ViewHook> };
      LiveSocketOptions: any;
    };
  }
}
