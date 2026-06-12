const routes = {
  '#/dashboard':            'dashboard.html',
  '#/login':                'pages/login.html',
  '#/signup':               'pages/signup.html',
  '#/reset-password':       'pages/reset-password.html',
  '#/unauthorized':         'pages/unauthorized.html',

  '#/users':              'pages/users-list.html',
  '#/users/new':          'pages/users-form.html',
  '#/users/:id':          'pages/users-detail.html',
  '#/users/:id/edit':     'pages/users-form.html',
  '#/users/:id/delete':   'pages/users-delete.html',

  '#/projects':             'pages/projects-list.html',
  '#/projects/wizard':      'pages/projects-wizard.html',
  '#/projects/confirm':     'pages/projects-confirm.html',
  '#/projects/new':         'pages/projects-form.html',
  '#/projects/:id':         'pages/projects-detail.html',
  '#/projects/:id/edit':    'pages/projects-form.html',
  '#/projects/:id/delete':  'pages/projects-delete.html',

  '#/showcase':             'pages/showcase-list.html',
  '#/showcase/new':         'pages/showcase-form.html',
  '#/showcase/:id':         'pages/showcase-detail.html',
  '#/showcase/:id/edit':    'pages/showcase-form.html',
  '#/showcase/:id/delete':  'pages/showcase-delete.html',

  '#/pricing':              'pages/pricing-list.html',
  '#/pricing/new':          'pages/pricing-form.html',
  '#/pricing/:id':          'pages/pricing-detail.html',
  '#/pricing/:id/edit':     'pages/pricing-form.html',
  '#/pricing/:id/delete':   'pages/pricing-delete.html',
};

export default routes;
