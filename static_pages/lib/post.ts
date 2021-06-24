import { getAllFilesFrontMatter } from './mdx';

export type Post = {
  slug: string;
  date: string;
  title: string;
  tags: string[];
  draft: boolean;
  summary: string;
  lastmod: string;
  images: string[];
};

export type PostImage = {
  url: string;
  alt: string;
};

const getAllPosts = async (): Promise<Post[]> => {
  return getAllFilesFrontMatter('posts');
};

const getAllTags = async (): Promise<string[]> => {
  return (await getAllFilesFrontMatter('posts')).flatMap(
    (post: Post) => post.tags || []
  );
};

export { getAllPosts, getAllTags };
