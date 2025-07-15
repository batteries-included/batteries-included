interface FullPageContainerProps {
  /** The content to display inside the full page container */
  children: React.ReactNode;
  /** Additional CSS classes to apply to the container */
  className?: string;
}

/**
 * A reusable full page container component for login pages
 *
 * This component provides a consistent full-height layout with proper spacing,
 * background colors, and responsive design for login pages.
 */
export function FullPageContainer({
  children,
  className = '',
}: FullPageContainerProps) {
  return (
    <div
      className={`min-h-screen bg-gray-lightest dark:bg-gray-darker flex flex-col justify-center py-12 sm:px-6 lg:px-8 ${className}`.trim()}>
      {children}
    </div>
  );
}
