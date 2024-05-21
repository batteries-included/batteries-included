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
        <button className="data-[state='open']:text-primary group flex items-center gap-x-1.5 focus:outline-none">
          <p className="group-hover:text-primary duration-300">{label}</p>
          <div className="text-secondary-gray group-data-[state='open']:text-primary group-hover:text-primary duration-300 group-data-[state='open']:translate-y-0.5 group-data-[state='open']:-rotate-180">
            <TriangleDownIcon width={25} height={25} />
          </div>
        </button>
      </Dropdown.Trigger>
      <Dropdown.Portal>
        <Dropdown.Content
          className="u-shadow animate-fade animate-duration-300 -translate-x- z-40 hidden max-w-[600px] rounded-xl bg-white p-6 lg:block"
          sideOffset={5}>
          {children}
          <Dropdown.Arrow width={20} height={10} className="fill-white" />
        </Dropdown.Content>
      </Dropdown.Portal>
    </Dropdown.Root>
  );
}
