import { forwardRef } from 'react';
import { useIsPasswordRevealed } from 'keycloakify/tools/useIsPasswordRevealed';
import type { I18n } from '../login/i18n';
import { Eye, EyeOff } from './icons';

export interface PasswordInputProps {
  /** The i18n object for localization */
  i18n: I18n;
  /** The ID for the password input element */
  passwordInputId: string;
  /** Whether the input has an error state */
  hasError: boolean;
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
      i18n,
      passwordInputId,
      hasError,
      name = passwordInputId,
      autoComplete,
      autoFocus,
      tabIndex,
      className = '',
    } = props;

    const { msgStr } = i18n;

    const { isPasswordRevealed, toggleIsPasswordRevealed } =
      useIsPasswordRevealed({ passwordInputId });

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

    const errorClasses = hasError
      ? ['bg-red-50 dark:bg-red-950', 'border-red-200 dark:border-red-900']
      : [];

    const inputClasses = [...baseClasses, ...errorClasses, className]
      .filter(Boolean)
      .join(' ');

    return (
      <div className="relative">
        <input
          ref={ref}
          id={passwordInputId}
          name={name}
          type={isPasswordRevealed ? 'text' : 'password'}
          autoComplete={autoComplete}
          autoFocus={autoFocus}
          tabIndex={tabIndex}
          aria-invalid={hasError}
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
          {isPasswordRevealed ? <EyeOff /> : <Eye />}
        </button>
      </div>
    );
  }
);
