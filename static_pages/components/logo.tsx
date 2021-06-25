import Link from '@/components/link';

const Logo = () => {
  return (
    <Link href="/">
      <img
        src="/logo.2.clip.png"
        alt="Batteries Included"
        width="40"
        height="40"
        className="m-1 w-7 h-7"
      />
    </Link>
  );
};

export default Logo;
