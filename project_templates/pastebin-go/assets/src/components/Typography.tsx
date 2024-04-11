type Props = {
  children: JSX.Element | JSX.Element[] | string;
};

function H1({ children }: Props) {
  return (
    <h1 className="mb-4 text-3xl font-extrabold leading-none tracking-tight text-gray-900 md:text-4xl lg:text-5xl">
      {children}
    </h1>
  );
}

function H2({ children }: Props) {
  return <h2 className="text-2xl font-bold">{children}</h2>;
}

export { H1, H2 };
