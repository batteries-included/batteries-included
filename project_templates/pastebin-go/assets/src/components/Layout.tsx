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
    <div className="min-h-screen bg-gray-50 flex flex-col w-full cursor-hand">
      <PageHeader />
      <MOTDDisplay message={motd.message} />
      <div className="container mx-auto mt-8 lg:max-w-2xl">
        <Outlet />
      </div>
    </div>
  );
};
export default Layout;
