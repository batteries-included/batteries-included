import PageHeader from './PageHeader';
import { Outlet, useLoaderData } from 'react-router-dom';
import { MOTDDisplay } from './motd';

interface MOTDResponse {
  message: string;
  status: string;
}

export const Layout = () => {
  const motd = useLoaderData() as MOTDResponse;
  return (
    <div className="cursor-hand flex min-h-screen w-full flex-col bg-gray-lightest">
      <PageHeader />
      <MOTDDisplay message={motd.message} />
      <div className="container mx-auto mt-8 lg:max-w-2xl">
        <Outlet />
      </div>
    </div>
  );
};
export default Layout;
