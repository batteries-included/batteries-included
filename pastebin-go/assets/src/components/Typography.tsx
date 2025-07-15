import React from 'react';

export const H1 = ({ children }: React.PropsWithChildren) => {
  return (
    <h1 className="mb-4 text-3xl font-extrabold leading-none tracking-tight text-gray-darker md:text-4xl lg:text-5xl">
      {children}
    </h1>
  );
};

export const H2 = ({ children }: React.PropsWithChildren) => {
  return <h2 className="text-2xl font-bold">{children}</h2>;
};
