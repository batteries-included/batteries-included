import { kcSanitize } from 'keycloakify/lib/kcSanitize';

interface FieldErrorProps {
  /** The error message to display */
  message: string;
  /** The HTML id attribute for the error element (for accessibility) */
  id?: string;
  /** Additional CSS classes to apply to the error message */
  className?: string;
}

/**
 * A reusable field error component for displaying validation errors below form inputs
 *
 * This component provides a consistent inline error message display with proper styling
 * for both light and dark themes. It automatically sanitizes the message content using
 * Keycloak's built-in sanitization function.
 */
export function FieldError({ message, id, className = '' }: FieldErrorProps) {
  return (
    <p
      className={`mt-2 text-sm text-red-600 dark:text-red-400 ${className}`.trim()}
      id={id}
      role="alert"
      aria-live="polite">
      {kcSanitize(message)}
    </p>
  );
}
