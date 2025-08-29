import * as Dialog from '@radix-ui/react-dialog';
import { Cross2Icon } from '@radix-ui/react-icons';

interface VideoModal {
  url: string;
  children: React.ReactNode;
}

export default function VideoModal({ url, children }: VideoModal) {
  return (
    <Dialog.Root>
      <Dialog.Trigger asChild>
        <div>{children}</div>
      </Dialog.Trigger>
      <Dialog.Portal>
        <Dialog.Overlay className="data-[state=open]:animate-fade data-[state=open]:animate-duration-300 fixed inset-0 z-50 bg-black/60" />
        <Dialog.Content className="data-[state=open]:animate-fade data-[state=open]:animate-duration-300 fixed left-[50%] top-[50%] z-50 h-[85vh] w-[70vw] translate-x-[-50%] translate-y-[-50%] rounded-[6px] bg-white p-[25px] focus:outline-none">
          <div className="flex items-center justify-between">
            <img src="/images/logo.svg" alt="logo" className="h-8 w-auto" />
            <Dialog.Close asChild>
              <button className="focus:outline-none" aria-label="Close">
                <Cross2Icon className="size-8" />
              </button>
            </Dialog.Close>
          </div>
          <div className="h-full pb-12 pt-8">
            <iframe
              className="h-full w-full rounded-[6px]"
              src={url}
              title="YouTube video player"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
              referrerPolicy="strict-origin-when-cross-origin"
              allowFullScreen></iframe>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
