import { forwardRef, useEffect, useReducer } from 'react';
import { EyeIcon, EyeSlashIcon } from '@heroicons/react/24/solid';
import { clsx } from 'clsx';
import { FieldError } from './fieldError';
import { I18n } from '../../i18n';

export interface PasswordInputProps {
  id: string;
  i18n: I18n;
  errors?: string[];
  /** The name attribute for the input (defaults to passwordInputId) */
  name?: string;
  /** The autocomplete attribute value */
  autoComplete?: string;
  /** Whether the input should be focused on mount */
  autoFocus?: boolean;
  /** The tabIndex for the input */
  tabIndex?: number;
  /** Additional CSS classes */
  className?: string;

  required?: boolean;
  disabled?: boolean;
  readOnly?: boolean;
}

/**
 * A password input component with show/hide functionality
 *
 * This component provides a password input field with a toggle button
 * to show or hide the password text. It includes proper accessibility
 * attributes and error state styling.
 */
export const PasswordInput = forwardRef<HTMLInputElement, PasswordInputProps>(
  function PasswordInput(props, ref) {
    const {
      id,
      i18n,
      errors = [],
      name,
      autoComplete,
      autoFocus,
      tabIndex,
      className = '',
    } = props;

    const { msgStr } = i18n;

    const passwordInputId = `${id}-input`;

    const [isPasswordRevealed, toggleIsPasswordRevealed] = useReducer(
      (isPasswordRevealed: boolean) => !isPasswordRevealed,
      false
    );

    useEffect(() => {
      const passwordInputElement = document.getElementById(passwordInputId);
      if (!(passwordInputElement instanceof HTMLInputElement)) {
        console.warn(
          `Element with ID "${passwordInputId}" is not an input element.`
        );
        return;
      }
      passwordInputElement.type = isPasswordRevealed ? 'text' : 'password';
    }, [isPasswordRevealed]);

    const baseClasses = [
      'px-3 py-2 w-full rounded-lg focus:ring-0',
      'text-sm text-gray-darkest dark:text-gray-lighter',
      'placeholder:text-gray-light dark:placeholder:text-gray-dark',
      'border border-gray-lighter dark:border-gray-darker-tint',
      'enabled:hover:border-primary enabled:dark:hover:border-gray',
      'focus:border-primary dark:focus:border-gray',
      'bg-gray-lightest dark:bg-gray-darkest-tint',
      'disabled:opacity-50',
      'pr-10',
    ];

    const inputClasses = clsx(
      baseClasses,
      errors.length > 0 && [
        'bg-red-50 dark:bg-red-950',
        'border-red-200 dark:border-red-900',
      ],
      className
    );

    return (
      <>
        <div className="relative">
          <input
            ref={ref}
            id={id}
            name={name}
            type={isPasswordRevealed ? 'text' : 'password'}
            autoComplete={autoComplete}
            autoFocus={autoFocus}
            tabIndex={tabIndex}
            required={props.required}
            disabled={props.disabled}
            readOnly={props.readOnly}
            aria-invalid={errors.length > 0}
            className={inputClasses}
          />
          <button
            type="button"
            className="absolute inset-y-0 right-0 pr-3 flex items-center hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 rounded-r-lg"
            aria-label={msgStr(
              isPasswordRevealed ? 'hidePassword' : 'showPassword'
            )}
            aria-controls={passwordInputId}
            onClick={toggleIsPasswordRevealed}>
            {isPasswordRevealed ? (
              <EyeIcon className="h-5 w-5 text-gray-400 hover:text-gray-500" />
            ) : (
              <EyeSlashIcon className="h-5 w-5 text-gray-400 hover:text-gray-500" />
            )}
          </button>
        </div>
        {errors?.map((error, index) => (
          <FieldError key={index} message={error} id={`${id}-error-${index}`} />
        ))}
      </>
    );
  }
);
