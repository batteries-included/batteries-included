/* eslint-disable @next/next/no-img-element */

import EmailForm from '@/components/email-form';
import Header from '@/components/header';

const navigation = [
  { name: 'Product', href: '/' },
  { name: 'Features', href: '/#features' },
  { name: 'Posts', href: '/posts' },
];

export default function Hero() {
  return (
    <div className="relative overflow-hidden bg-white">
      <div
        className="hidden lg:block lg:absolute lg:inset-0"
        aria-hidden="true"
      >
        <svg
          className="absolute top-0 transform translate-x-64 -translate-y-8 left-1/2"
          width={640}
          height={784}
          fill="none"
          viewBox="0 0 640 784"
        >
          <defs>
            <pattern
              id="9ebea6f4-a1f5-4d96-8c4e-4c2abf658047"
              x={118}
              y={0}
              width={20}
              height={20}
              patternUnits="userSpaceOnUse"
            >
              <rect
                x={0}
                y={0}
                width={4}
                height={4}
                className="text-gray-200"
                fill="currentColor"
              />
            </pattern>
          </defs>
          <rect
            y={72}
            width={640}
            height={640}
            className="text-gray-50"
            fill="currentColor"
          />
          <rect
            x={118}
            width={404}
            height={784}
            fill="url(#9ebea6f4-a1f5-4d96-8c4e-4c2abf658047)"
          />
        </svg>
      </div>

      <div className="relative pt-6 pb-16 sm:pb-24 lg:pb-32">
        <Header navigation={navigation} />

        <main className="px-4 mx-auto mt-16 max-w-7xl sm:mt-24 sm:px-6 lg:mt-32">
          <div className="lg:grid lg:grid-cols-12 lg:gap-8">
            <div className="sm:text-center md:max-w-2xl md:mx-auto lg:col-span-6 lg:text-left">
              <h1>
                <span className="block text-sm font-semibold tracking-wide text-gray-500 uppercase sm:text-base lg:text-sm xl:text-base">
                  Coming soon
                </span>
                <span className="block mt-1 text-4xl font-extrabold tracking-tight sm:text-5xl xl:text-6xl">
                  <span className="block text-gray-900">
                    Software infrastructure for tomorrow&apos;s
                  </span>
                  <span className="block text-pink-600">
                    technology business
                  </span>
                </span>
              </h1>
              <p className="mt-3 text-base text-gray-500 sm:mt-5 sm:text-xl lg:text-lg xl:text-xl">
                Batteries Included Infrastructure is more powerful and easier to
                use than any public or private cloud. Everything that your
                technology teams need without complexity.
              </p>
              <div className="mt-8 sm:max-w-lg sm:mx-auto sm:text-center lg:text-left lg:mx-0">
                <p className="text-base font-medium text-gray-900">
                  Sign up to get notified when it’s ready.
                </p>
                <EmailForm />
              </div>
            </div>
            <div className="relative mt-12 bg-white shadow-2xl rounded-3xl sm:max-w-lg sm:mx-auto lg:mt-0 lg:max-w-none lg:mx-0 lg:col-span-6 lg:flex lg:items-center">
              <img
                src="/logo.2.white.png"
                alt="Batteries Included Logo"
                className="p-5"
              />
            </div>
            .
          </div>
        </main>
      </div>
    </div>
  );
}
