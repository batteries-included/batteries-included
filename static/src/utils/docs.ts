import type { CollectionEntry } from 'astro:content';
import { getCollection } from 'astro:content';
import type { Doc } from '~/types';
import { cleanSlug } from './permalinks';

const getNormalizedDoc = async (doc: CollectionEntry<'doc'>): Promise<Doc> => {
  const { id, slug: rawSlug = '', data } = doc;
  const { Content, headings } = await doc.render();

  const {
    title,
    description,
    tags: rawTags = [],
    category: rawCategory,
    draft = false,
    metadata = {},
  } = data as {
    title: string;
    description?: string;
    tags?: string[];
    category?: string;
    draft?: boolean;
    metadata?: Record<string, unknown>;
  };

  const slug = cleanSlug(rawSlug); // cleanSlug(rawSlug.split('/').pop());
  const category = rawCategory ? cleanSlug(rawCategory) : undefined;
  const tags = rawTags.map((tag: string) => cleanSlug(tag));

  return {
    id: id,

    slug: slug,

    permalink: '/docs/' + slug,

    title: title,
    description: description,
    category: category,
    tags: tags,

    draft: draft,

    metadata,

    headings,

    Content: Content,
  };
};

const load = async function (): Promise<Array<Doc>> {
  const docs = await getCollection('doc');

  const normalizedDocs = docs.map(async (doc) => await getNormalizedDoc(doc));

  const categoryOrder = [
    'getting-started',
    'batteries',
    'development',
    'uncategorized',
  ];

  const results = (await Promise.all(normalizedDocs))
    .filter((doc) => !doc.draft)
    .sort((a, b) => {
      const aCategory = categoryOrder.indexOf(a.category || 'uncategorized');
      const bCategory = categoryOrder.indexOf(b.category || 'uncategorized');
      if (aCategory === bCategory) {
        return a.title.localeCompare(b.title);
      }
      return aCategory - bCategory;
    });

  return results;
};

let _docs: Array<Doc>;

export const fetchDocs = async (): Promise<Array<Doc>> => {
  if (!_docs) {
    _docs = await load();
  }

  return _docs;
};

export const getStaticPathsDoc = async () => {
  return (await fetchDocs()).flatMap((doc) => ({
    params: { slug: doc.slug },
    props: { doc },
  }));
};

export const getStaticPathsDocsList = async ({ paginate }) => {
  return paginate(await fetchDocs(), {
    params: { blog: '/docs' },
    pageSize: 20,
  });
};

export const getRelatedDocs = async (doc: Doc, num: number = 4) => {
  const docs = await fetchDocs();
  const docWordSet = wordSet(doc);
  const other = docs.filter((d) => d.id !== doc.id);
  const scores = other.map((d) => {
    const tags = new Set(d.tags);
    const common = (doc.tags || []).filter((tag) => tags.has(tag));
    const mult = 1 + common.length * 0.1;
    const words = wordSet(d);
    const commonWords = [...words].filter((w) => docWordSet.has(w));
    return mult * commonWords.length;
  });
  const withScore: [Doc, number][] = other.map((d, i) => [d, scores[i]]);
  return withScore
    .sort((a: [Doc, number], b: [Doc, number]) => b[1] - a[1])
    .slice(0, num)
    .map((e) => e[0]);
};

const wordSet = (d: Doc) => {
  const titleWords = d.title.split(' ').map((w) => w.toLowerCase());
  const bodyWords =
    d.Content?.toString()
      .split(' ')
      .map((w) => w.toLowerCase()) || [];
  const words = [...titleWords, ...bodyWords].filter((w) => w.length > 3);
  return new Set(words);
};
