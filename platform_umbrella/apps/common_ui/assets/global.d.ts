import { LiveSocket, ViewHook } from 'phoenix_live_view';

declare global {
  interface Window {
    liveSocket: LiveSocket;
    storybook: {
      Hooks: { [name: string]: Partial<ViewHook> };
      LiveSocketOptions: any;
    };
  }
}
