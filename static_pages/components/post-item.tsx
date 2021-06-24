import React, { FunctionComponent } from 'react';

import Link from '@/components/link';
import Tag from '@/components/tag';
import { Post } from '@/lib/post';
import siteMetadata from '@/lib/site-metadata';

const postDateTemplate: Intl.DateTimeFormatOptions = {
  year: 'numeric',
  month: 'long',
  day: 'numeric',
};

type PostItemParams = { post: Post };
const PostItem: FunctionComponent<PostItemParams> = ({ post }) => {
  const { slug, date, title, summary, tags } = post;
  return (
    <li key={slug} className="py-12">
      <article>
        <div className="space-y-2 xl:grid xl:grid-cols-4 xl:space-y-0 xl:items-baseline">
          <dl>
            <dt className="sr-only">Published on</dt>
            <dd className="text-base font-medium leading-6 text-gray-500 dark:text-gray-400">
              <time dateTime={date}>
                {new Date(date).toLocaleDateString(
                  siteMetadata.locale,
                  postDateTemplate
                )}
              </time>
            </dd>
          </dl>
          <div className="space-y-5 xl:col-span-3">
            <div className="space-y-6">
              <div>
                <h2 className="text-2xl font-bold leading-8 tracking-tight">
                  <Link
                    href={`/posts/${slug}`}
                    className="text-gray-900 dark:text-gray-100"
                  >
                    {title}
                  </Link>
                </h2>
                <div className="flex flex-wrap">
                  {tags.map((tag) => (
                    <Tag key={tag} text={tag} />
                  ))}
                </div>
              </div>
              <div className="prose text-gray-500 max-w-none dark:text-gray-400">
                {summary}
              </div>
            </div>
            <div className="text-base font-medium leading-6">
              <Link
                href={`/posts/${slug}`}
                className="text-pink-500 hover:text-pink-600 dark:hover:text-pink-400"
                aria-label={`Read "${title}"`}
              >
                Read more &rarr;
              </Link>
            </div>
          </div>
        </div>
      </article>
    </li>
  );
};

export default PostItem;
