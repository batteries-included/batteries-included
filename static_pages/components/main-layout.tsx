import { FunctionComponent } from 'react';

import Header from '@/components/header';

const navigation = [
  { name: 'Product', href: '/' },
  { name: 'Features', href: '/#features' },
  { name: 'Posts', href: '/posts' },
];

const MainLayout: FunctionComponent = ({ children }) => {
  return (
    <div className="relative overflow-hidden bg-white">
      <div className="relative pt-6 pb-8 sm:pb-16 lg:pb-24">
        <Header navigation={navigation} />
      </div>
      {children}
    </div>
  );
};

export default MainLayout;
