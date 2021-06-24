import { FunctionComponent } from 'react';

import Link from '@/components/link';
import kebabCase from '@/lib/utils/kebab-case';

type Props = {
  text: string;
};

const Tag: FunctionComponent<Props> = ({ text }) => {
  return (
    <Link
      href={`/tags/${kebabCase(text)}`}
      className="mr-3 text-sm font-medium text-pink-500 uppercase hover:text-pink-600 dark:hover:text-pink-400"
    >
      {text.split(' ').join('-')}
    </Link>
  );
};

export default Tag;
