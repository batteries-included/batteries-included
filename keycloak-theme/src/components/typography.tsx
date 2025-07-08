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
