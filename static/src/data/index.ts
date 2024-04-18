import slugify from 'slugify';

export const getRecentTags = (data) => {
  const allTags = [...new Set(data.flatMap((post) => post.tags))];

  const tagsFormat = allTags.map((tag: string) => ({
    label: tag,
    link: `/tags/${slugify(tag, { lower: true })}`,
  }));
  const orderTags = tagsFormat.sort((a: any, b: any) => a.label - b.label);

  return orderTags.slice(0, 4);
};
