import { kcSanitize } from 'keycloakify/lib/kcSanitize';
import { H3 } from './typography';

interface ErrorMessageProps {
    /** The error message to display */
    message: string;
    /** Additional CSS classes to apply to the container */
    className?: string;
}

/**
 * A reusable error message component for displaying validation errors
 * 
 * This component provides a consistent error message display with an error icon
 * and proper styling for both light and dark themes.
 */
export function ErrorMessage({ message, className = '' }: ErrorMessageProps) {
    return (
        <div className={`mb-4 rounded-md bg-red-50 dark:bg-red-950 text-red-500 dark:text-red-50 p-4 ${className}`.trim()}>
            <div className="flex">
                <div className="flex-shrink-0">
                    <svg
                        className="h-5 w-5"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        aria-hidden="true">
                        <path
                            fillRule="evenodd"
                            d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z"
                            clipRule="evenodd"
                        />
                    </svg>
                </div>
                <div className="ml-3">
                    <H3>{kcSanitize(message)}</H3>
                </div>
            </div>
        </div>
    );
}
