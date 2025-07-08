import { ReactNode } from 'react';
import { TextInput } from './input/text';
import { PasswordInput } from './input/password';
import type { I18n } from '../i18n';
import SelectInput from './input/select';
import HiddenInput from './input/hidden';

interface FieldProps {
  /** The field label */
  label: ReactNode;
  /** The field label ID (for accessibility) */
  labelId?: string;
  /** The input field name */
  name: string;
  /** The input field ID */
  id: string;
  /** The input type (default: 'text') */
  type?:
  | 'text'
  | 'email'
  | 'tel'
  | 'url'
  | 'password'
  | 'select'
  | 'textarea'
  | 'multiselect'
  | 'multi-select'
  | 'hidden';
  /** The input value */
  value?: string;
  /** The default input value */
  defaultValue?: string;
  /** The placeholder text */
  placeholder?: string;
  /** Whether the input should be auto-focused */
  autoFocus?: boolean;
  /** Autocomplete attribute */
  autoComplete?: string;
  /** Tab index for keyboard navigation */
  tabIndex?: number;
  /** Whether the input is required */
  required?: boolean;
  /** Whether the input is disabled */
  disabled?: boolean;
  /** Whether the input is readonly */
  readOnly?: boolean;
  /** Additional CSS classes to apply to the input */
  inputClassName?: string;
  /** Additional CSS classes to apply to the field container */
  className?: string;
  errors?: string[];
  /** i18n object for password input localization (required when type is 'password') */
  i18n?: I18n;
  /** Additional input attributes */
  [key: string]: unknown;
}

/**
 * A complete field component that includes a label and input with consistent styling
 *
 * This component provides a full form field with proper accessibility attributes,
 * consistent styling, and error handling. It can be used with the default TextInput
 * or with custom input components passed as children.
 */
export function Field({
  label,
  labelId,
  name,
  id,
  type = 'text',
  value,
  defaultValue,
  placeholder,
  autoFocus,
  autoComplete,
  tabIndex,
  required,
  disabled,
  readOnly,
  inputClassName,
  className = '',
  errors,
  i18n,
  ...rest
}: FieldProps) {
  return (
    <div className={className}>
      <label
        htmlFor={id}
        id={labelId}
        className="block text-sm font-medium text-gray-700 dark:text-gray-300">
        {label}
      </label>
      <div className="mt-1">
        {
          // | 'text' | 'email' | 'tel' | 'url' are all handled by TextInput so handle that here
          type === 'text' ||
            type === 'email' ||
            type === 'tel' ||
            type === 'url' ? (
            <TextInput
              name={name}
              id={id}
              type={type}
              value={value}
              defaultValue={defaultValue}
              placeholder={placeholder}
              autoFocus={autoFocus}
              autoComplete={autoComplete}
              tabIndex={tabIndex}
              required={required}
              disabled={disabled}
              readOnly={readOnly}
              className={inputClassName}
              errors={errors}
              {...rest}
            />
          ) : null
        }

        {type === 'password' && i18n ? (
          <PasswordInput
            id={id}
            name={name}
            autoFocus={autoFocus}
            autoComplete={autoComplete}
            tabIndex={tabIndex}
            required={required}
            disabled={disabled}
            readOnly={readOnly}
            className={inputClassName}
            errors={errors}
            i18n={i18n}
            {...rest}
          />
        ) : null}

        {type === 'select' ? (
          <SelectInput
            inputId={id}
            name={name}
            value={value}
            defaultValue={defaultValue}
            placeholder={placeholder}
            autoFocus={autoFocus}
            tabIndex={tabIndex}
            required={required}
            isDisabled={disabled || readOnly}
            className={inputClassName}
            isMulti={false}
            {...rest}
          />
        ) : null}

        {type === 'multiselect' || type === 'multi-select' ? (
          <SelectInput
            inputId={id}
            name={name}
            value={value}
            defaultValue={defaultValue}
            placeholder={placeholder}
            autoFocus={autoFocus}
            tabIndex={tabIndex}
            required={required}
            isDisabled={disabled || readOnly}
            className={inputClassName}
            isMulti={true}
            {...rest}
          />
        ) : null}

        {type === 'textarea' ? (
          <TextInput
            id={id}
            name={name}
            value={value}
            defaultValue={defaultValue}
            placeholder={placeholder}
            autoFocus={autoFocus}
            autoComplete={autoComplete}
            tabIndex={tabIndex}
            required={required}
            disabled={disabled}
            readOnly={readOnly}
            className={inputClassName}
            errors={errors}
            rows={4} // Default rows for textarea
            {...rest}
          />
        ) : null}

        {type === 'hidden' ? (
          <HiddenInput id={id} name={name} value={value} {...rest} />
        ) : null}
      </div>
    </div>
  );
}
