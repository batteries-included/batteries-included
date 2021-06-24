/* eslint-disable react/jsx-props-no-spreading */
import Link from 'next/link';
import { AnchorHTMLAttributes, FunctionComponent } from 'react';

type Props = AnchorHTMLAttributes<HTMLAnchorElement>;

const CustomLink: FunctionComponent<Props> = ({ href, children, ...rest }) => {
  const isInternalLink = `${href}`.startsWith('/');
  const isAnchorLink = `${href}`.startsWith('#');

  if (isAnchorLink) {
    return (
      <a href={`${href}`} {...rest}>
        {children}
      </a>
    );
  }
  if (isInternalLink) {
    return (
      <Link href={href || ''}>
        <a {...rest}>{children}</a>
      </Link>
    );
  }

  return (
    <a target="_blank" rel="noopener noreferrer" href={`${href}`} {...rest}>
      {children}
    </a>
  );
};

export default CustomLink;
