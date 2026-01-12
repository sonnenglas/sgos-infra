// @ts-check

const gitCommit = process.env.GIT_COMMIT || 'dev';
const gitCommitShort = gitCommit.substring(0, 7);

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'SGOS Docs',
  tagline: 'Sonnenglas Operating System',
  favicon: 'img/favicon.ico',

  url: 'https://sgos-infra.sgl.as',
  baseUrl: '/',

  organizationName: 'sonnenglas',
  projectName: 'sgos-docs',

  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  themes: [
    [
      '@easyops-cn/docusaurus-search-local',
      {
        hashed: true,
        docsRouteBasePath: '/',
        indexBlog: false,
      },
    ],
  ],

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.js',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      navbar: {
        title: 'SGOS',
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'docs',
            position: 'left',
            label: 'Docs',
          },
          {
            href: `https://github.com/sonnenglas/sgos-infra/commit/${gitCommit}`,
            label: gitCommitShort,
            position: 'right',
            title: 'View deployed commit on GitHub',
          },
        ],
      },
      footer: {
        style: 'light',
        copyright: `Sonnenglas Infrastructure Documentation`,
      },
      prism: {
        theme: require('prism-react-renderer').themes.github,
        darkTheme: require('prism-react-renderer').themes.dracula,
        additionalLanguages: ['bash', 'json', 'yaml', 'python', 'docker'],
      },
      colorMode: {
        defaultMode: 'light',
        disableSwitch: false,
        respectPrefersColorScheme: true,
      },
    }),
};

module.exports = config;
