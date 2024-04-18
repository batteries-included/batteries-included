import * as Dropdown from '@radix-ui/react-dropdown-menu';
import { TriangleDownIcon } from '@radix-ui/react-icons';

interface DropdownMenuProps {
  label: string;
  children: React.ReactNode;
}

export default function DropdownMenu({ label, children }: DropdownMenuProps) {
  return (
    <Dropdown.Root>
      <Dropdown.Trigger asChild>
        <button className="flex items-center gap-x-1.5 data-[state='open']:text-primary focus:outline-none group">
          <p className="group-hover:text-primary duration-300">{label}</p>
          <div className="text-secondary-gray group-data-[state='open']:text-primary group-hover:text-primary group-data-[state='open']:translate-y-0.5 group-data-[state='open']:-rotate-180 duration-300">
            <TriangleDownIcon width={25} height={25} />
          </div>
        </button>
      </Dropdown.Trigger>
      <Dropdown.Portal>
        <Dropdown.Content
          className="hidden lg:block bg-white p-6 rounded-xl max-w-[600px] u-shadow animate-fade animate-duration-300 -translate-x- z-40"
          sideOffset={5}>
          {children}
          <Dropdown.Arrow width={20} height={10} className="fill-white" />
        </Dropdown.Content>
      </Dropdown.Portal>
    </Dropdown.Root>
  );
}
