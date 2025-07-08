import { assert } from 'keycloakify/tools/assert';
import { FieldError } from './fieldError';

import { clsx } from 'clsx';

export type TextInputProps = {
  id: string;
  name: string;
  value?: string;
  placeholder?: string;
  required?: boolean;
  disabled?: boolean;
  readOnly?: boolean;
  rows?: number;
  className?: string;
  errors?: string[];
} & Omit<React.InputHTMLAttributes<HTMLTextAreaElement>, 'value' | 'type'>;

export default function TextInput({
  id,
  name,
  value = '',
  placeholder = '',
  required = false,
  disabled = false,
  readOnly = false,
  rows = 4,
  className = '',
  errors = [],
  ...rest
}: TextInputProps) {
  assert(id, 'id is required');
  assert(name, 'name is required');

  const inputClasses = clsx(
    'block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-darker ',
    'outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline-2 focus:-outline-offset-2',
    'bg-gray-light dark:bg-gray-darker',
    'border-gray dark:border-gray-darker-tint',
    'focus:outline-none focus:ring-primary focus:border-primary',
    'disabled:opacity-50',
    errors.length > 0 &&
      'border-red-500 bg-red-50 dark:bg-red-900 text-red-900 dark:text-red-100'
  );

  return (
    <>
      <textarea
        id={id}
        name={name}
        rows={rows}
        value={value}
        placeholder={placeholder}
        required={required}
        disabled={disabled}
        readOnly={readOnly}
        className={`${inputClasses} ${className}`}
        {...rest}
        defaultValue={''}
      />
      {errors.map((error, index) => (
        <FieldError key={index} message={error} id={`${id}-error-${index}`} />
      ))}
    </>
  );
}
