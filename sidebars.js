/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  docs: [
    'intro',
    'rationale',
    {
      type: 'category',
      label: 'Apps',
      collapsed: false,
      items: [
        'apps/overview',
        'apps/app-schema',
        'apps/api-strategy',
      ],
    },
    {
      type: 'category',
      label: 'Infrastructure',
      collapsed: false,
      items: [
        'infrastructure/architecture',
        'infrastructure/deployment',
        'infrastructure/monitoring',
        'infrastructure/backups',
        'infrastructure/secrets',
        'infrastructure/cloudflare',
        'infrastructure/authentication',
        'infrastructure/disaster-recovery',
      ],
    },
  ],
};

module.exports = sidebars;
