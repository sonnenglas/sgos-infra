/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  docs: [
    'intro',
    {
      type: 'category',
      label: 'Concept',
      collapsed: false,
      items: ['concept/sgos'],
    },
    {
      type: 'category',
      label: 'Architecture',
      collapsed: false,
      items: [
        'architecture/overview',
        'architecture/api-strategy',
        'architecture/app-schema',
      ],
    },
    {
      type: 'category',
      label: 'Operations',
      collapsed: false,
      items: [
        'operations/deployment',
        'operations/backups',
      ],
    },
    {
      type: 'category',
      label: 'Services',
      items: [
        'services/monitoring',
        'services/glitchtip',
      ],
    },
  ],
};

module.exports = sidebars;
