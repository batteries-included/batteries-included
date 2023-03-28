import { defineCollection, z } from 'astro:content';

const defaultSchema = {
  schema: z.object({
    title: z.string(),
    draft: z.boolean(),
    date: z.date(),
    tags: z.array(z.string()).optional(),
  }),
};

const posts = defineCollection(defaultSchema);
const company_docs = defineCollection(defaultSchema);
const technical_design = defineCollection(defaultSchema);

export const collections = { posts, company_docs, technical_design };
