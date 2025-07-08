import { ReactNode } from 'react';
import { TextInput } from './textInput';
import { PasswordInput } from './passwordInput';
import type { I18n } from '../login/i18n';

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
    type?: 'text' | 'email' | 'tel' | 'url' | 'search' | 'password';
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
    /** Whether there is a validation error */
    hasError?: boolean;
    /** The error message to display */
    errorMessage?: string;
    /** Error field ID for accessibility */
    errorId?: string;
    /** Custom input element to render instead of TextInput */
    children?: ReactNode;
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
    hasError,
    errorMessage,
    errorId,
    children,
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
                {children || (
                    type === 'password' && i18n ? (
                        <>
                            <PasswordInput
                                i18n={i18n}
                                passwordInputId={id}
                                hasError={hasError || false}
                                name={name}
                                autoComplete={autoComplete}
                                autoFocus={autoFocus}
                                tabIndex={tabIndex}
                                className={inputClassName}
                            />
                            {hasError && errorMessage && (
                                <div className="mt-2 text-sm text-red-600 dark:text-red-400" role="alert" aria-live="polite">
                                    {errorMessage}
                                </div>
                            )}
                        </>
                    ) : (
                        <TextInput
                            name={name}
                            id={id}
                            type={type === 'password' ? 'text' : type}
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
                            hasError={hasError}
                            errorMessage={errorMessage}
                            errorId={errorId}
                            {...rest}
                        />
                    )
                )}
            </div>
        </div>
    );
}
