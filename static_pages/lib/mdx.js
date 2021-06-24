import rehypePrism from '@mapbox/rehype-prism';
import fs from 'fs';
import matter from 'gray-matter';
import { serialize } from 'next-mdx-remote/serialize';
import path from 'path';
import readingTime from 'reading-time';
import rehypeKatex from 'rehype-katex';
import remarkAutolink from 'remark-autolink-headings';
import remarkCode from 'remark-code-titles';
import remarkMath from 'remark-math';
import remarkSlug from 'remark-slug';

// import visit from 'unist-util-visit';
import getAllFilesRecursively from '@/lib/utils/files';

const root = process.cwd();

// const tokenClassNames = {
//   tag: 'text-code-red',
//   'attr-name': 'text-code-yellow',
//   'attr-value': 'text-code-green',
//   deleted: 'text-code-red',
//   inserted: 'text-code-green',
//   punctuation: 'text-code-white',
//   keyword: 'text-code-purple',
//   string: 'text-code-green',
//   function: 'text-code-blue',
//   boolean: 'text-code-red',
//   comment: 'text-gray-400 italic',
// };

export function getFiles(type) {
  const prefixPaths = path.join(root, type);
  const files = getAllFilesRecursively(prefixPaths);
  // Only want to return blog/path and ignore root, replace is needed to work on Windows
  return files.map((file) =>
    file.slice(prefixPaths.length + 1).replace(/\\/g, '/')
  );
}

export function formatSlug(slug) {
  return slug.replace(/\.(mdx|md)/, '');
}

export function dateSortDesc(a, b) {
  if (a > b) return -1;
  if (a < b) return 1;
  return 0;
}

export async function getFileBySlug(type, slug) {
  const mdxPath = path.join(root, type, `${slug}.mdx`);
  const mdPath = path.join(root, type, `${slug}.md`);
  const source = fs.existsSync(mdxPath)
    ? fs.readFileSync(mdxPath, 'utf8')
    : fs.readFileSync(mdPath, 'utf8');

  const { data, content } = matter(source);
  const mdxSource = await serialize(content, {
    mdxOptions: {
      remarkPlugins: [remarkSlug, remarkAutolink, remarkCode, remarkMath],
      rehypePlugins: [
        rehypeKatex,
        rehypePrism,
        // () => {
        //   return (tree) => {
        //     visit(tree, 'element', (node, _index, _parent) => {
        //       const [token, type] = node.properties.className || [];
        //       if (token === 'token') {
        //         node.properties.className = [tokenClassNames[type]];
        //       }
        //     });
        //   };
        // },
      ],
    },
  });

  return {
    mdxSource,
    frontMatter: {
      readingTime: readingTime(content),
      slug: slug || null,
      fileName: fs.existsSync(mdxPath) ? `${slug}.mdx` : `${slug}.md`,
      ...data,
    },
  };
}

export async function getAllFilesFrontMatter(folder) {
  const prefixPaths = path.join(root, folder);

  const files = getAllFilesRecursively(prefixPaths);

  const allFrontMatter = [];

  files.forEach((file) => {
    // Replace is needed to work on Windows
    const fileName = file.slice(prefixPaths.length + 1).replace(/\\/g, '/');
    // Remove Unexpected File
    if (path.extname(fileName) !== '.md' && path.extname(fileName) !== '.mdx') {
      return;
    }
    const source = fs.readFileSync(file, 'utf8');
    const { data } = matter(source);
    if (data.draft !== true) {
      allFrontMatter.push({ ...data, slug: formatSlug(fileName) });
    }
  });

  return allFrontMatter.sort((a, b) => dateSortDesc(a.date, b.date));
}
