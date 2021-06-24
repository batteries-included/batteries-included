import Head from 'next/head';

import FeaturesSection from '@/components/features-section';
import Hero from '@/components/hero';

export default function Home() {
  return (
    <div>
      <Head>
        <title>Batteries Included</title>
        <meta name="description" content="Batteries Included" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <Hero />
      <FeaturesSection />
      <footer />
    </div>
  );
}
