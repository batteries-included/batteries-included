/* eslint-disable react/jsx-props-no-spreading */
import { MDXRemote, MDXRemoteSerializeResult } from 'next-mdx-remote';
import { FunctionComponent } from 'react';

import MDXComponents from '@/components/mdx-components';
import PostLayout from '@/components/post-layout';
import { FrontMatter } from '@/lib/front';
import { formatSlug, getFileBySlug } from '@/lib/mdx';
import { getAllPosts, getAllPublisedPosts, Post as PostType } from '@/lib/post';

export async function getStaticPaths() {
  const posts = await getAllPosts();
  return {
    paths: posts.map((p: PostType) => ({
      params: { slug: p.slug },
    })),
    fallback: false,
  };
}

type InnerPropsParams = {
  slug: string;
};
type PropParams = {
  params: InnerPropsParams;
};
export async function getStaticProps({ params }: PropParams) {
  const publishedPosts = await getAllPublisedPosts();
  const postIndex = publishedPosts.findIndex(
    (post) => formatSlug(post.slug) === `${params.slug}`
  );
  const prev = publishedPosts[postIndex + 1] || null;
  const next = publishedPosts[postIndex - 1] || null;
  const post = await getFileBySlug('posts', params.slug);

  return { props: { post, prev, next } };
}

type CurrentPost = {
  frontMatter: FrontMatter;
  mdxSource: MDXRemoteSerializeResult;
};

type PostParams = {
  post: CurrentPost;
  prev: PostType;
  next: PostType;
};
const Post: FunctionComponent<PostParams> = ({ post, prev, next }) => {
  const { mdxSource, frontMatter } = post;

  return (
    <PostLayout frontMatter={frontMatter} prev={prev} next={next}>
      <MDXRemote {...mdxSource} components={MDXComponents} />
    </PostLayout>
  );
};

export default Post;
