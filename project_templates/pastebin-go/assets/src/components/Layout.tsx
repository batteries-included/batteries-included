// The major layout of the application

import PageHeader from './PageHeader';

type Props = {
  children: JSX.Element | JSX.Element[];
};

function Layout({ children }: Props) {
  return (
    <div className="min-h-screen bg-gray-50 flex flex-col w-full cursor-hand">
      <PageHeader />
      <div className="container mx-auto mt-8 lg:max-w-2xl">{children}</div>
    </div>
  );
}

export default Layout;
