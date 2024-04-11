import { useLoaderData } from 'react-router-dom';
import { H1 } from '../components/Typography';
import { Paste } from '../types';

function PastePage() {
  const paste: Paste = useLoaderData() as Paste;

  return (
    <div className="flex flex-col gap-8 py-8">
      <H1>{paste.title}</H1>
      <pre className="text-wrap">{paste.content}</pre>
    </div>
  );
}

export default PastePage;
