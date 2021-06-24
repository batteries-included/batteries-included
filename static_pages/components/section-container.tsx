import { FunctionComponent } from 'react';

const SectionContainer: FunctionComponent = ({ children }) => {
  return (
    <div className="max-w-3xl px-4 mx-auto sm:px-6 xl:max-w-5xl xl:px-0">
      {children}
    </div>
  );
};

export default SectionContainer;
