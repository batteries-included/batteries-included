import { FunctionComponent } from 'react';

import MainLayout from '@/components/main-layout';
import PostItem from '@/components/post-item';
import SectionContainer from '@/components/section-container';
import { getAllPosts, Post } from '@/lib/post';

const MAX_DISPLAY = 10;

type IndexProps = {
  posts: Post[];
};
const Index: FunctionComponent<IndexProps> = ({ posts }) => {
  return (
    <MainLayout>
      <SectionContainer>
        <ul className="divide-y divide-gray-200 dark:divide-gray-700">
          {!posts.length && 'No posts found.'}
          {posts.slice(0, MAX_DISPLAY).map((p) => {
            return <PostItem post={p} key={p.slug} />;
          })}
        </ul>
      </SectionContainer>
    </MainLayout>
  );
};

const getStaticProps = async () => {
  const posts = await getAllPosts();
  return { props: { posts } };
};

export { getStaticProps };
export default Index;
