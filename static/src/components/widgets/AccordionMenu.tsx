import * as Accordion from '@radix-ui/react-accordion';
import { ChevronDownIcon } from '@radix-ui/react-icons';

interface AccordionMenuProps {
  label?: string;
  children: React.ReactNode;
}

export default function AccordionMenu({ label, children }: AccordionMenuProps) {
  return (
    <Accordion.Root type="multiple">
      <Accordion.Item value={label || ''}>
        <Accordion.Trigger asChild>
          <button className="group flex w-full items-center justify-between">
            <p className="group-data-[state='open']:text-primary text-xl font-medium duration-300">
              {label}
            </p>
            <ChevronDownIcon
              className="group-data-[state='open']:text-primary duration-300 group-data-[state='open']:-rotate-180"
              width={30}
              height={30}
            />
          </button>
        </Accordion.Trigger>
        <Accordion.Content className="mt-4">{children}</Accordion.Content>
      </Accordion.Item>
    </Accordion.Root>
  );
}
