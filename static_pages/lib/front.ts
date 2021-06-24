import { Post } from '@/lib/post';

export type FrontMatter = Post & {
  fileName?: string;
};
