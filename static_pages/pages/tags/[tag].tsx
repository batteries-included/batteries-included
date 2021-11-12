import { FunctionComponent } from 'react';

import MainLayout from '@/components/main-layout';
import PageTitle from '@/components/page-title';
import PostItem from '@/components/post-item';
import SectionContainer from '@/components/section-container';
import { getAllPublisedPosts, getAllTags, Post } from '@/lib/post';
import kebabCase from '@/lib/utils/kebab-case';

const MAX_DISPLAY = 10;
type Params = {
  posts: Post[];
  tag: string;
};
const Tag: FunctionComponent<Params> = ({ posts, tag }) => {
  const title = tag.toUpperCase();

  return (
    <MainLayout>
      <SectionContainer>
        <PageTitle>{title}</PageTitle>
        <ul className="divide-y divide-gray-200 dark:divide-gray-700">
          {!posts.length && 'No posts found.'}
          {posts.slice(0, MAX_DISPLAY).map((p: Post) => {
            return <PostItem post={p} key={p.slug} />;
          })}
        </ul>
      </SectionContainer>
    </MainLayout>
  );
};

const getStaticPaths = async () => {
  const tags = await getAllTags();

  return {
    paths: tags
      .map((tag) => kebabCase(tag))
      .map((tag) => ({
        params: {
          tag,
        },
      })),
    fallback: false,
  };
};

type InnerStaticParams = {
  tag: string;
};
type StaticParams = {
  params: InnerStaticParams;
};
const getStaticProps = async ({ params }: StaticParams) => {
  const posts = (await getAllPublisedPosts()).filter((post: Post) =>
    post.tags.map((t: string) => kebabCase(t)).includes(params.tag)
  );
  return { props: { posts, tag: params.tag } };
};

export { getStaticPaths, getStaticProps };
export default Tag;
