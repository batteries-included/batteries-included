import { FieldError } from './fieldError';

interface TextInputProps {
    /** The input field name */
    name: string;
    /** The input field ID */
    id: string;
    /** The input type (default: 'text') */
    type?: 'text' | 'email' | 'tel' | 'url' | 'search';
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
    className?: string;
    /** Whether there is a validation error */
    hasError?: boolean;
    /** The error message to display */
    errorMessage?: string;
    /** Error field ID for accessibility */
    errorId?: string;
    /** Additional input attributes */
    [key: string]: unknown;
}

/**
 * A reusable text input component that follows the Keycloak theme's design patterns
 *
 * This component provides consistent styling for text inputs with error states,
 * including proper color changes and error message display. It automatically
 * applies the correct styles based on the hasError prop.
 */
export function TextInput({
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
    className = '',
    hasError,
    errorMessage,
    errorId,
    ...rest
}: TextInputProps) {
    const inputClasses = [
        'px-3 py-2 w-full rounded-lg focus:ring-0',
        'text-sm text-gray-darkest dark:text-gray-lighter',
        'placeholder:text-gray-light dark:placeholder:text-gray-dark',
        'border border-gray-lighter dark:border-gray-darker-tint',
        'enabled:hover:border-primary enabled:dark:hover:border-gray',
        'focus:border-primary dark:focus:border-gray',
        'bg-gray-lightest dark:bg-gray-darkest-tint',
        'disabled:opacity-50',
        hasError && [
            'bg-red-50 dark:bg-red-950',
            'border-red-200 dark:border-red-900',
        ],
        className
    ]
        .flat()
        .filter(Boolean)
        .join(' ');

    return (
        <>
            <input
                id={id}
                name={name}
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
                aria-invalid={hasError}
                className={inputClasses}
                {...rest}
            />
            {hasError && errorMessage && (
                <FieldError message={errorMessage} id={errorId} />
            )}
        </>
    );
}
