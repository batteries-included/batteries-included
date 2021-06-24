import {
  BeakerIcon,
  CalculatorIcon,
  ChartSquareBarIcon,
  ChipIcon,
  CogIcon,
  DatabaseIcon,
  GlobeAltIcon,
  HomeIcon,
  LightningBoltIcon,
  LockClosedIcon,
  ServerIcon,
  ShieldCheckIcon,
} from '@heroicons/react/outline';

const features = [
  { name: 'Powerful Control Center', icon: HomeIcon, description: '' },
  { name: 'Data Science', icon: CalculatorIcon, description: '' },
  { name: 'ML Operations', icon: BeakerIcon, description: '' },
  { name: 'Serverless PaaS', icon: LightningBoltIcon, description: '' },
  { name: 'Advanced Security', icon: ShieldCheckIcon, description: '' },
  { name: 'Automated Operations', icon: CogIcon, description: '' },
  { name: 'Databases', icon: DatabaseIcon, description: '' },
  { name: 'Networking', icon: GlobeAltIcon, description: '' },
  { name: 'Monitoring', icon: ChartSquareBarIcon, description: '' },
  { name: 'User Management', icon: LockClosedIcon, description: '' },
  { name: 'Developer Tools', icon: ChipIcon, description: '' },
  { name: 'Cloud Integrated', icon: ServerIcon, description: '' },
];

const FeaturesSection = () => (
  <div className="relative py-16 bg-white sm:py-24 lg:py-32">
    <div className="max-w-md px-4 mx-auto text-center sm:max-w-3xl sm:px-6 lg:px-8 lg:max-w-7xl">
      <a id="features">
        <h2 className="text-base font-semibold tracking-wider text-pink-600 uppercase">
          Build Your Business
        </h2>
      </a>
      <p className="mt-2 text-3xl font-extrabold tracking-tight text-gray-900 sm:text-4xl">
        Everything you need to build tomorrow&apos;s technology company
      </p>
      <p className="mx-auto mt-5 text-xl text-gray-500 max-w-prose">
        All of the systems needed to run a modern company are complex, but
        necessary. When combined correctly they can super charge your business;
        making software fast, stable, and able to predict the future. Tech
        giants know this and invest heavily in their infrastructure. Let our
        teams design, build, and operate the Batteries Included platform.
      </p>
      <div className="mt-12">
        <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((feature) => (
            <div key={feature.name} className="pt-6">
              <div className="flow-root px-6 pb-8 rounded-lg bg-gray-50">
                <div className="-mt-6">
                  <div>
                    <span className="inline-flex items-center justify-center p-3 bg-pink-500 rounded-md shadow-lg">
                      <feature.icon
                        className="w-6 h-6 text-white"
                        aria-hidden="true"
                      />
                    </span>
                  </div>
                  <h3 className="mt-8 text-lg font-medium tracking-tight text-gray-900">
                    {feature.name}
                  </h3>
                  <p className="mt-5 text-base text-gray-500">
                    {feature.description}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  </div>
);

export default FeaturesSection;
