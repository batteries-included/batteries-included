import { Link } from 'react-router-dom';
import logo from '../assets/logo.svg';

export const PageHeader = () => {
  return (
    <header className="flex h-14 gap-6 bg-white px-4 shadow-lg">
      <Link to={'/'} className="flex items-center justify-center">
        <img src={logo} alt="logo" className="mr-4 size-12" />

        <div className="flex flex-col justify-center whitespace-nowrap text-sm leading-none">
          <div className="mb-1 font-semibold tracking-[0.25rem]">BATTERIES</div>
          <div className="text-[0.6125rem] tracking-[0.35rem]">INCLUDED</div>
        </div>
      </Link>
      <div className="ml-auto flex items-center justify-center">
        <h1 className="text-xl font-semibold font-mono">Pastebin</h1>
      </div>
    </header>
  );
};

export default PageHeader;
