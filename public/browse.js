// Browser for the content this server offers.
//
// RetroArch finds its way around through the .index / .index-dirs /
// .index-extended files that build.sh writes into every served directory, so
// this reads exactly the same files: one request per directory visited, cached
// for the rest of the session, and no directory listing needed on the server.
(function () {
  'use strict';

  // Entries per page. Big enough to be useful, small enough that a core
  // directory with thousands of zips stays responsive.
  var PAGE_SIZE = 50;

  // The server root has no index files of its own - build.sh only indexes
  // inside these - so they are the starting points.
  var ROOTS = ['cores', 'frontend', 'system'];

  var tableEl = document.getElementById('browse-table');
  var bodyEl = document.getElementById('browse-list');
  var crumbEl = document.getElementById('browse-breadcrumb');
  var statusEl = document.getElementById('browse-status');
  var pagerEl = document.getElementById('browse-pager');
  var prevEl = document.getElementById('browse-prev');
  var nextEl = document.getElementById('browse-next');
  var pageEl = document.getElementById('browse-page');

  // path -> entries, so walking back up the tree or flipping pages never
  // re-requests an index file.
  var cache = {};

  function joinPath(path, name) {
    return path ? path + '/' + name : name;
  }

  // Encode each segment separately so slashes stay path separators.
  function encodePath(path) {
    return path.split('/').map(encodeURIComponent).join('/');
  }

  function toLines(text) {
    return text.split('\n').map(function (line) {
      return line.trim();
    }).filter(function (line) {
      return line.length > 0;
    });
  }

  // A missing index file is normal (.index-extended only exists for cores), so
  // every failure reads as "no entries" rather than an error.
  function readIndex(path, name) {
    var url = (path ? encodePath(path) + '/' : '') + name;
    return fetch(url).then(function (response) {
      return response.ok ? response.text() : '';
    }, function () {
      return '';
    });
  }

  // ".index-extended" lines are "<date> <crc> <name>"; a name may hold spaces.
  function parseExtended(text) {
    var meta = {};
    toLines(text).forEach(function (line) {
      var parts = /^(\S+)\s+(\S+)\s+(.+)$/.exec(line);
      if (parts) {
        meta[parts[3]] = { date: parts[1], crc: parts[2] };
      }
    });
    return meta;
  }

  function loadDir(path) {
    if (cache[path]) {
      return Promise.resolve(cache[path]);
    }
    // build.sh only writes .index-extended under cores, so don't ask elsewhere.
    var extended = path === 'cores' || path.indexOf('cores/') === 0;
    return Promise.all([
      readIndex(path, '.index-dirs'),
      readIndex(path, '.index'),
      extended ? readIndex(path, '.index-extended') : ''
    ]).then(function (texts) {
      var dirs = toLines(texts[0]);
      var files = toLines(texts[1]);
      var meta = parseExtended(texts[2]);

      if (!path && !dirs.length && !files.length) {
        dirs = ROOTS.slice();
      }

      // .index-extended can mention a zip that .index does not, so take both.
      Object.keys(meta).forEach(function (name) {
        if (files.indexOf(name) === -1) {
          files.push(name);
        }
      });
      files.sort();

      cache[path] = dirs.map(function (name) {
        return { name: name, dir: true };
      }).concat(files.map(function (name) {
        return {
          name: name,
          dir: false,
          date: meta[name] ? meta[name].date : '',
          crc: meta[name] ? meta[name].crc : ''
        };
      }));
      return cache[path];
    });
  }

  function route() {
    var hash = window.location.hash.replace(/^#\/?/, '');
    var page = 1;
    var query = hash.indexOf('?');
    if (query !== -1) {
      var found = /(?:^|&)p=(\d+)/.exec(hash.slice(query + 1));
      if (found) {
        page = parseInt(found[1], 10);
      }
      hash = hash.slice(0, query);
    }
    var path = hash.split('/').filter(function (part) {
      return part.length > 0 && part !== '.' && part !== '..';
    }).map(function (part) {
      try {
        return decodeURIComponent(part);
      } catch (error) {
        return part;
      }
    }).join('/');
    return { path: path, page: page };
  }

  function routeHash(path, page) {
    return '#/' + encodePath(path) + (page > 1 ? '?p=' + page : '');
  }

  function crumb(label, href) {
    var item = document.createElement('li');
    if (href) {
      var link = document.createElement('a');
      link.href = href;
      link.textContent = label;
      item.appendChild(link);
    } else {
      item.textContent = label;
      item.setAttribute('aria-current', 'page');
    }
    crumbEl.appendChild(item);
    return item;
  }

  function renderBreadcrumb(path) {
    crumbEl.textContent = '';
    var parts = path ? path.split('/') : [];
    crumb('All content', parts.length ? routeHash('', 1) : '');
    var walked = '';
    parts.forEach(function (part, index) {
      walked = joinPath(walked, part);
      crumb(part, index === parts.length - 1 ? '' : routeHash(walked, 1));
    });
  }

  function cell(text) {
    var td = document.createElement('td');
    td.textContent = text || '—';
    return td;
  }

  function row(entry, path) {
    var tr = document.createElement('tr');
    var name = document.createElement('th');
    var link = document.createElement('a');
    var full = joinPath(path, entry.name);
    name.setAttribute('scope', 'row');
    link.href = entry.dir ? routeHash(full, 1) : encodePath(full);
    link.textContent = entry.dir ? entry.name + '/' : entry.name;
    name.appendChild(link);
    tr.appendChild(name);
    tr.appendChild(cell(entry.date));
    tr.appendChild(cell(entry.crc));
    return tr;
  }

  function render(entries, path, page) {
    var pages = Math.max(1, Math.ceil(entries.length / PAGE_SIZE));
    page = Math.min(Math.max(1, page), pages);
    var first = (page - 1) * PAGE_SIZE;
    var shown = entries.slice(first, first + PAGE_SIZE);

    bodyEl.textContent = '';
    shown.forEach(function (entry) {
      bodyEl.appendChild(row(entry, path));
    });

    tableEl.hidden = entries.length === 0;
    statusEl.textContent = entries.length
      ? 'Showing ' + (first + 1) + '–' + (first + shown.length) +
        ' of ' + entries.length + ' item' + (entries.length === 1 ? '' : 's') + '.'
      : 'Nothing here. Run "make" on the server to build its indexes.';

    pagerEl.hidden = pages < 2;
    pageEl.textContent = 'Page ' + page + ' of ' + pages;
    prevEl.disabled = page === 1;
    nextEl.disabled = page === pages;
    prevEl.onclick = function () {
      window.location.hash = routeHash(path, page - 1);
    };
    nextEl.onclick = function () {
      window.location.hash = routeHash(path, page + 1);
    };
  }

  function show() {
    var wanted = route();
    renderBreadcrumb(wanted.path);
    statusEl.textContent = 'Loading…';
    loadDir(wanted.path).then(function (entries) {
      // Drop a response the user has already navigated away from.
      if (route().path === wanted.path) {
        render(entries, wanted.path, route().page);
      }
    });
  }

  window.addEventListener('hashchange', show);
  show();
})();
