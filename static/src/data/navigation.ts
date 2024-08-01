import { fetchPosts } from '~/utils/posts';
import { getRecentTags } from '.';
import { getAsset } from '../utils/permalinks';

const allBlogPosts = await fetchPosts();

export type HeaderDataProps = {
  label?: string;
  link?: string;
  children?: {
    label?: string;
    link?: string;
    description?: string;
    icon?: string;
    children?: {
      label?: string;
      link?: string;
    }[];
  }[];
};

export const headerData = [
  {
    label: 'Home',
    link: '/',
  },
  {
    label: 'Batteries For',
    link: '',
    children: [
      {
        label: 'Database',
        link: '/solutions/database',
        description: 'Automated PostgreSQL on any cloud or hardware.',
        icon: 'database',
      },
      {
        label: 'Artificial Intelligence',
        description:
          "Purpose built AI and ML tools for today's modern business needs.",
        icon: 'ai',
        link: '/solutions/ai',
      },
      {
        label: 'Web Services',
        description: 'Deploy serverless services at breakneck speeds safely.',
        icon: 'web',
        link: '/solutions/web-deploy',
      },
      {
        label: 'Operational Tools',
        description:
          'Ahe best tools for ops integrated into a single control panel.',
        icon: 'automation',
        link: '/solutions/sre_tools',
      },
      {
        label: 'Security',
        description:
          'From OAuth to mTLS Batteries included provides uncompromising security.',
        icon: 'secure',
        link: '/solutions/security',
      },
    ],
  },
  // {
  //   label: 'Docs',
  //   link: '',
  //   children: [
  //     {
  //       label: 'Database',
  //       description: '',
  //       icon: 'database',
  //       link: '/docs/database',
  //       children: [
  //         {
  //           label: 'Cloud Native Postgres',
  //           link: '/docs/cloud-nativ',
  //         },
  //         {
  //           label: 'PostgreSQL',
  //           link: '/docs/postgres',
  //         },
  //         {
  //           label: 'Redis',
  //           link: '/docs/redis',
  //         },
  //       ],
  //     },
  //     {
  //       label: 'Web Services',
  //       description: '',
  //       icon: 'web',
  //       link: '/docs/web-deploy',
  //       children: [
  //         {
  //           label: 'Knative',
  //           link: '/docs/knative',
  //         },
  //         {
  //           label: 'Blue/Green Deployments',
  //           link: '/docs/blue-green-deployments',
  //         },
  //         {
  //           label: 'Scaling',
  //           link: '/docs/scaling',
  //         },
  //       ],
  //     },
  //     {
  //       label: 'Monitoring',
  //       description: '',
  //       icon: 'monitoring',
  //       link: '/docs/monitoring',
  //       children: [
  //         {
  //           label: 'Grafana',
  //           link: '/docs/grafana',
  //         },
  //         {
  //           label: 'Victoria Metrics',
  //           link: '/docs/victoria-metrics',
  //         },
  //         {
  //           label: 'Alertmanager',
  //           link: '/docs/alertmanager',
  //         },
  //       ],
  //     },
  //     {
  //       label: 'Networking/Security',
  //       description: '',
  //       icon: 'secure',
  //       link: '/docs/security',
  //       children: [
  //         {
  //           label: 'Istio',
  //           link: '/docs/istio',
  //         },
  //         {
  //           label: 'Cert manager',
  //           link: '/docs/cert-manager',
  //         },
  //         {
  //           label: 'Keycloak',
  //           link: '/docs/keycloak',
  //         },
  //       ],
  //     },
  //     {
  //       label: 'Operational Tools',
  //       description: '',
  //       icon: 'automation',
  //       link: '/docs/sre_tools',
  //       children: [
  //         {
  //           label: 'Edit History',
  //           link: '/docs/edit-history',
  //         },
  //         {
  //           label: 'Kubernetes Live View',
  //           link: '/docs/kubernetes-live-view',
  //         },
  //       ],
  //     },
  //   ],
  // },
  {
    label: 'Posts',
    link: '',
    children: [
      {
        label: 'Posts',
        description: '',
        icon: 'document',
        link: '/posts',
        children: allBlogPosts.slice(0, 4).map((item: any) => ({
          label: item.title,
          link: `/posts/${item.slug}`,
        })),
      },
      {
        label: 'Tags',
        description: '',
        icon: 'hashtag',
        link: '/tags',
        children: getRecentTags(allBlogPosts),
      },
      {
        label: 'Other',
        description: '',
        icon: 'other',
        children: [
          {
            label: 'All Tags',
            link: '/all-tags',
          },
          {
            label: 'Post Archive',
            link: '/post-archive',
          },
        ],
      },
    ],
  },
  {
    label: 'Pricing',
    link: '/pricing',
  },
  {
    label: 'Sign Up',
    link: '/sign-up',
  },
];

export const footerData = {
  links: [
    {
      title: 'Product',
      links: [{ text: 'Pricing', href: '/pricing' }],
    },
    {
      title: 'Support',
      links: [
        { text: 'Docs', href: '/docs' },
        { text: 'Github', href: 'https://github.com/batteries-included' },
        { text: 'Batteries Included License', href: '/LICENSE-1.0' },
      ],
    },
  ],
  secondaryLinks: [],
  socialLinks: [
    {
      ariaLabel: 'Github',
      icon: 'tabler:brand-github',
      href: 'https://github.com/batteries-included',
    },
    { ariaLabel: 'RSS', icon: 'tabler:rss', href: getAsset('/rss.xml') },
  ],
};
