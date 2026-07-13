/* Timbitwire web app — tiny client-side router.
   Reads templates from #routeSource (in DOM) + window.__extraRoutes (injected
   by routes-2.js) and shows the one matching the current sidebar selection.
   Persists selection to localStorage. Also handles mobile drawer. */

(function () {
  const sideItems = document.querySelectorAll('.side .item[data-route]');
  const canvas = document.getElementById('canvas');
  const crumb1 = document.getElementById('crumb1');
  const crumb2 = document.getElementById('crumb2');

  // Collect templates from <template> elements
  const routes = {};
  document.querySelectorAll('#routeSource template[data-route]').forEach(t => {
    routes[t.dataset.route] = {
      html: t.innerHTML,
      crumb: t.dataset.crumb || '',
      title: t.dataset.title || t.dataset.route
    };
  });
  // Merge JS-injected routes
  Object.assign(routes, window.__extraRoutes || {});

  const DEFAULT = 'dashboard';
  const stored = localStorage.getItem('tgs_route');
  const initial = routes[stored] ? stored : DEFAULT;

  function nav(name) {
    const r = routes[name] || routes[DEFAULT];
    if (!r) return;
    canvas.innerHTML = r.html;
    canvas.scrollTop = 0;
    window.scrollTo({ top: 0, behavior: 'instant' });
    // update sidebar highlight
    sideItems.forEach(i => i.classList.toggle('active', i.dataset.route === name));
    // update breadcrumbs
    const parts = (r.crumb || '').split('·').map(s => s.trim());
    crumb1.textContent = parts[0] || '';
    crumb2.textContent = parts[1] || r.title || '';
    // persist
    localStorage.setItem('tgs_route', name);
    // close mobile drawer
    document.getElementById('sidebar').classList.remove('open');
    document.getElementById('scrim').classList.remove('on');
  }

  sideItems.forEach(i => {
    i.addEventListener('click', e => { e.preventDefault(); nav(i.dataset.route); });
  });

  // Mobile menu toggle
  const menuBtn = document.getElementById('menuBtn');
  const scrim = document.getElementById('scrim');
  menuBtn.addEventListener('click', () => {
    document.getElementById('sidebar').classList.toggle('open');
    scrim.classList.toggle('on');
  });
  scrim.addEventListener('click', () => {
    document.getElementById('sidebar').classList.remove('open');
    scrim.classList.remove('on');
  });

  // Initial render
  nav(initial);

  // Expose for debugging + inter-app deep links (?route=finance)
  window.__nav = nav;
  const q = new URLSearchParams(location.search).get('route');
  if (q && routes[q]) nav(q);
})();
