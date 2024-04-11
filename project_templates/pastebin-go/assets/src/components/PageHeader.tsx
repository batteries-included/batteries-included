import { Link } from 'react-router-dom';
import logo from '../assets/logo.svg';

function PageHeader() {
  return (
    <header className="flex bg-white h-14 px-4 gap-6 shadow-lg">
      <Link to={'/'} className="flex items-center justify-center">
        <img src={logo} alt="logo" className="size-12 mr-4" />

        <div className="flex flex-col justify-center text-sm leading-none whitespace-nowrap">
          <div className="font-semibold tracking-[0.25rem] mb-1">BATTERIES</div>
          <div className="text-[0.6125rem] tracking-[0.35rem]">INCLUDED</div>
        </div>
      </Link>
      <div className="ml-auto flex items-center justify-center">
        <h1 className="font-semibold text-xl">Pastebin</h1>
      </div>
    </header>
  );
}

export default PageHeader;
