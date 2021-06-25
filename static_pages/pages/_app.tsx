/* eslint-disable react/jsx-props-no-spreading */
/* eslint-disable */
import '../styles/globals.css';

import type { AppProps } from 'next/app';
// prism
import Prism from 'prismjs';
import 'prismjs/components/prism-bash'
import 'prismjs/components/prism-elixir'
import 'prismjs/components/prism-javascript'
// Done with prism
import { FunctionComponent, useEffect } from 'react';
import TagManager from 'react-gtm-module';

const tagManagerArgs = { gtmId: 'GTM-W9W5RW2' };

const BatteriesIncluded: FunctionComponent<AppProps> = ({
  Component,
  pageProps,
}) => {
  useEffect(() => {
    Prism.highlightAll();
    TagManager.initialize(tagManagerArgs);
  }, []);

  return <Component {...pageProps} />;
};
export default BatteriesIncluded;
