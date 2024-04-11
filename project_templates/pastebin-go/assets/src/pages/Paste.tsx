import { useLoaderData } from 'react-router-dom';
import Layout from '../components/Layout';
import { H1 } from '../components/Typography';

type Paste = {
  id: string;
  title: string;
  content: string;
  created_at: string;
};

function PastePage() {
  const paste: Paste = useLoaderData() as Paste;

  return (
    <Layout>
      <div className="flex flex-col gap-8 py-8">
        <H1>{paste.title}</H1>
        <pre className="text-wrap">{paste.content}</pre>
      </div>
    </Layout>
  );
}

export default PastePage;
