import { useState } from 'react';

interface PricingCardProps {
  title: string;
  description: string;
  options?: string[];
  preference?: {
    description: string;
    battery: {
      price: number;
      quantity: number;
      per: string;
    };
    pod: {
      price: number;
      quantity: number;
      per: string;
    };
  };
}

export default function PricingCard({
  title,
  description,
  options,
  preference,
}: PricingCardProps) {
  const [battery, setBattery] = useState(preference?.battery.quantity || 0);
  const [pod, setPod] = useState(preference?.pod.quantity || 0);

  return (
    <div className="p-5 bg-white rounded-2xl border border-[#DADADA]">
      <h2 className="text-xl lg:text-2xl font-semibold">{title}</h2>
      <p className="nt-2">{description}</p>
      <div className="mt-4 mb-5 h-[1px] bg-[#DADADA]">&nbsp;</div>
      {options && (
        <ul className="space-y-2">
          {options.map((opt, i) => (
            <li key={`opt-${i + 1}`} className="flex items-center gap-x-2.5">
              <img src="/images/icons/check.svg" alt="check icon" />
              <p>{opt}</p>
            </li>
          ))}
        </ul>
      )}
      {preference && (
        <>
          <p>{preference.description}</p>
          <div className="mt-5 mb-3 space-y-4">
            <div className="flex items-center justify-center gap-x-4">
              <button
                onClick={() => battery > 1 && setBattery((prev) => prev - 1)}
                className="w-7 h-7 rounded-full border border-[#DADADA] grid place-items-center">
                -
              </button>
              <p className="w-20 text-center">
                <b>{battery + ''}</b> battery
              </p>
              <button
                onClick={() => setBattery((prev) => prev + 1)}
                className="w-7 h-7 rounded-full border border-[#DADADA] grid place-items-center">
                +
              </button>
              <p>
                <b>=</b>
              </p>
              <p>
                <b>${preference.battery.price * battery}</b> /per{' '}
                {preference.battery.per}
              </p>
            </div>
            <div className="flex items-center justify-center gap-x-4">
              <button
                onClick={() => pod > 1 && setPod((prev) => prev - 1)}
                className="w-7 h-7 rounded-full border border-[#DADADA] grid place-items-center">
                -
              </button>
              <p className="w-20 text-center">
                <b>{pod + ''}</b> pod
              </p>
              <button
                onClick={() => setPod((prev) => prev + 1)}
                className="w-7 h-7 rounded-full border border-[#DADADA] grid place-items-center">
                +
              </button>
              <p>
                <b>=</b>
              </p>
              <p>
                <b>${(preference.pod.price * pod).toFixed(2)}</b> /per{' '}
                {preference.pod.per}
              </p>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
