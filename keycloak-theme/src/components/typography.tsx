import React from 'react';

interface H2Props extends React.HTMLAttributes<HTMLHeadingElement> {
  children: React.ReactNode;
}

export function H2({ children, className = '', ...props }: H2Props) {
  return (
    <h2
      className={`mt-6 text-center text-3xl font-bold tracking-tight text-gray-darker dark:text-gray-lighter ${className}`.trim()}
      {...props}>
      {children}
    </h2>
  );
}

interface H3Props extends React.HTMLAttributes<HTMLHeadingElement> {
  children: React.ReactNode;
}

export function H3({ children, className = '', ...props }: H3Props) {
  return (
    <h3 className={`text-sm font-medium ${className}`.trim()} {...props}>
      {children}
    </h3>
  );
}
