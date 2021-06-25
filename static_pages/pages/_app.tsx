/* eslint-disable react/jsx-props-no-spreading */
import '../styles/globals.css';

import type { AppProps } from 'next/app';
import { FunctionComponent, useEffect } from 'react';
import TagManager from 'react-gtm-module';

const tagManagerArgs = { gtmId: 'GTM-W9W5RW2' };

const BatteriesIncluded: FunctionComponent<AppProps> = ({
  Component,
  pageProps,
}) => {
  useEffect(() => {
    TagManager.initialize(tagManagerArgs);
  }, []);

  return <Component {...pageProps} />;
};
export default BatteriesIncluded;
