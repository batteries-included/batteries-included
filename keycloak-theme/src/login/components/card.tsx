interface CardProps {
  /** The content to display inside the card */
  children: React.ReactNode;
  /** Additional CSS classes to apply to the outer container */
  className?: string;
  /** Additional CSS classes to apply to the inner card */
  cardClassName?: string;
}

/**
 * A reusable card component for login pages
 *
 * This component provides a consistent card layout with proper spacing,
 * background colors, and responsive design for login forms and content.
 */
export function Card({
  children,
  className = '',
  cardClassName = '',
}: CardProps) {
  return (
    <div
      className={`mt-8 sm:mx-auto sm:w-full sm:max-w-md ${className}`.trim()}>
      <div
        className={`bg-white dark:bg-gray-dark dark:text-white py-8 px-4 shadow sm:rounded-lg sm:px-10 ${cardClassName}`.trim()}>
        {children}
      </div>
    </div>
  );
}
