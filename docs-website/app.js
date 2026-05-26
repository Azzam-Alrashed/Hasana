/* -------------------------------------------------------------
 * HASANA DOCUMENTATION APP LOGIC
 * Client-side Router, Markdown Compiler, Search Engine, RTL Layout
 * ------------------------------------------------------------- */

// --- Global UI Translations ---
const uiTranslations = {
  en: {
    documents: "Documents",
    toc: "Table of Contents",
    searchPlaceholder: "Search documentation... (Esc to close)",
    searchTrigger: "Search specs...",
    date: "Date",
    status: "Status",
    owner: "Owner",
    readTime: "min read",
    themeDark: "Dark Mode",
    themeLight: "Light Mode",
    noResults: "No results found for",
    typeToSearch: "Type to search across documents...",
    backToTop: "Back to top"
  },
  ar: {
    documents: "المستندات",
    toc: "المحتويات",
    searchPlaceholder: "ابحث في المستندات... (Esc للإغلاق)",
    searchTrigger: "ابحث عن ملف...",
    date: "التاريخ",
    status: "الحالة",
    owner: "المالك",
    readTime: "دقائق للقراءة",
    themeDark: "المظهر الداكن",
    themeLight: "المظهر المضيء",
    noResults: "لم يتم العثور على نتائج لـ",
    typeToSearch: "اكتب للبحث في جميع المستندات...",
    backToTop: "الرجوع للأعلى"
  }
};

// --- App State ---
const state = {
  currentDocId: null,
  currentTheme: "dark",
  searchSelectedIndex: -1,
  searchResults: []
};

// --- Custom Markdown Render Settings ---
function setupMarkedRenderer() {
  if (typeof marked === 'undefined') return;

  const renderer = {
    heading(text, level, raw) {
      // Generate standard slug, removing formatting
      const slug = raw.toLowerCase()
        .replace(/[^\w\s\u0600-\u06FF-]/g, '') // keep letters, numbers, spaces, Arabic chars, hyphens
        .trim()
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-');
      
      return `<h${level} id="${slug}">${text}<a href="#docs/${state.currentDocId}#${slug}" class="anchor-link" aria-hidden="true">#</a></h${level}>`;
    },
    code(code, infostring, escaped) {
      const language = infostring || 'plaintext';
      const cleanCode = code.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
      return `<div class="code-block-wrapper">
        <button class="copy-code-btn" onclick="copyCode(this)">Copy</button>
        <pre><code class="language-${language}">${cleanCode}</code></pre>
      </div>`;
    }
  };

  marked.use({ renderer });
}

// --- Preprocess Markdown to support custom GitHub alerts ---
function preprocessMarkdown(text) {
  // Regex to match GitHub-style blockquote alerts, e.g. > [!NOTE]\n> Content...
  const calloutRegex = />\s*\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*\n((?:>\s*.*\n?)*)/g;
  
  return text.replace(calloutRegex, (match, type, content) => {
    // strip the '>' and leading spaces from blockquote content
    const cleanContent = content.split('\n')
      .map(line => line.replace(/^\s*>\s?/, ''))
      .join('\n');
    
    let iconSvg = '';
    switch(type) {
      case 'NOTE':
        iconSvg = '<svg class="callout-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>';
        break;
      case 'TIP':
        iconSvg = '<svg class="callout-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A5 5 0 0 0 8 8c0 1 .3 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5"></path><path d="M9 18h6"></path><path d="M10 22h4"></path></svg>';
        break;
      case 'IMPORTANT':
        iconSvg = '<svg class="callout-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 8v4"></path><path d="M12 16h.01"></path><circle cx="12" cy="12" r="10"></circle></svg>';
        break;
      case 'WARNING':
        iconSvg = '<svg class="callout-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>';
        break;
      case 'CAUTION':
        iconSvg = '<svg class="callout-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="7.86 2 16.14 2 22 7.86 22 16.14 16.14 22 7.86 22 2 16.14 2 7.86 7.86 2"></polygon><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>';
        break;
    }

    return `<div class="callout callout-${type.toLowerCase()}">
      <div class="callout-header">${iconSvg}<span>${type}</span></div>
      <div class="callout-content">${marked.parse(cleanContent)}</div>
    </div>`;
  });
}

// --- Copy Code to Clipboard ---
window.copyCode = function(button) {
  const pre = button.nextElementSibling;
  const code = pre.querySelector('code');
  navigator.clipboard.writeText(code.innerText).then(() => {
    button.innerText = 'Copied!';
    button.style.background = 'var(--primary)';
    button.style.borderColor = 'var(--primary)';
    setTimeout(() => {
      button.innerText = 'Copy';
      button.style.background = '';
      button.style.borderColor = '';
    }, 2000);
  }).catch(err => {
    console.error('Failed to copy text: ', err);
  });
};

// --- Theme Switcher Logic ---
function setTheme(theme) {
  state.currentTheme = theme;
  document.documentElement.setAttribute('data-theme', theme);
  localStorage.setItem('hasana-docs-theme', theme);
  
  // Update button texts
  const currentLang = state.currentDocId ? getDocById(state.currentDocId).metadata.lang : 'en';
  const label = theme === 'dark' ? uiTranslations[currentLang].themeLight : uiTranslations[currentLang].themeDark;
  
  const textEl = document.getElementById('theme-toggle-text');
  if (textEl) textEl.textContent = label;
}

function initTheme() {
  const savedTheme = localStorage.getItem('hasana-docs-theme');
  const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  const theme = savedTheme || (prefersDark ? 'dark' : 'light');
  setTheme(theme);
  
  document.getElementById('theme-toggle-btn').addEventListener('click', () => {
    setTheme(state.currentTheme === 'dark' ? 'light' : 'dark');
  });
}

// --- Helper: Retrieve Doc by ID ---
function getDocById(id) {
  return docsData.find(doc => doc.id === id) || docsData[0];
}

// --- UI Translation Hydrator ---
function hydrateUI(lang) {
  const t = uiTranslations[lang] || uiTranslations.en;
  
  // Set doc attribute
  document.documentElement.setAttribute('dir', lang === 'ar' ? 'rtl' : 'ltr');
  document.documentElement.setAttribute('lang', lang);
  
  // Update static UI elements
  document.getElementById('nav-section-docs-title').textContent = t.documents;
  document.getElementById('toc-pane-title').textContent = t.toc;
  document.getElementById('search-trigger-text').textContent = t.searchTrigger;
  document.getElementById('search-input').placeholder = t.searchPlaceholder;
  
  document.getElementById('label-date').textContent = t.date;
  document.getElementById('label-status').textContent = t.status;
  document.getElementById('label-owner').textContent = t.owner;
  
  // Update theme button text
  const label = state.currentTheme === 'dark' ? t.themeLight : t.themeDark;
  document.getElementById('theme-toggle-text').textContent = label;
}

// --- Sidebar Renderer ---
function renderSidebar() {
  const listContainer = document.getElementById('document-list');
  listContainer.innerHTML = '';
  
  docsData.forEach(doc => {
    const li = document.createElement('li');
    li.className = `nav-item ${doc.id === state.currentDocId ? 'active' : ''}`;
    li.id = `nav-item-${doc.id}`;
    
    // Status Badge translation
    const currentLang = doc.metadata.lang || 'en';
    const statusText = doc.metadata.status;
    let badgeClass = 'status-draft';
    if (statusText.toLowerCase().includes('approved')) badgeClass = 'status-approved';
    else if (statusText.toLowerCase().includes('idea')) badgeClass = 'status-idea';
    
    li.innerHTML = `
      <a href="#docs/${doc.id}" class="nav-link">
        <span class="nav-link-title">${doc.title}</span>
        <span class="badge ${badgeClass}" style="font-size: 0.65rem; padding: 1px 6px;">${doc.metadata.lang.toUpperCase()}</span>
      </a>
    `;
    listContainer.appendChild(li);
  });
}

// --- Dynamic TOC Renderer ---
let scrollSpyObserver = null;

function renderTOC() {
  const tocList = document.getElementById('toc-list');
  tocList.innerHTML = '';
  
  const headings = Array.from(document.querySelectorAll('#markdown-render h2, #markdown-render h3'));
  
  if (headings.length === 0) {
    document.getElementById('toc-panel').style.display = 'none';
    return;
  } else {
    // Show if hidden by empty state, but respect media queries (hide if desktop width not reached)
    document.getElementById('toc-panel').style.display = window.innerWidth > 1024 ? 'block' : 'none';
  }
  
  headings.forEach(heading => {
    const li = document.createElement('li');
    const level = heading.tagName.toLowerCase();
    const id = heading.id;
    const text = heading.textContent.replace(/#$/, '').trim(); // strip the anchor sign
    
    li.innerHTML = `
      <a href="#docs/${state.currentDocId}#${id}" class="toc-link toc-${level}">${text}</a>
    `;
    tocList.appendChild(li);
  });
  
  setupScrollspy(headings);
}

// --- Active Section Scrollspy ---
function setupScrollspy(headings) {
  if (scrollSpyObserver) scrollSpyObserver.disconnect();
  
  const tocLinks = document.querySelectorAll('.toc-link');
  const articleEl = document.getElementById('doc-article');
  
  const options = {
    root: articleEl,
    rootMargin: '0px 0px -65% 0px', // check elements in the upper section of scroll height
    threshold: 0
  };
  
  let activeHeadingId = null;
  
  scrollSpyObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        activeHeadingId = entry.target.id;
        
        tocLinks.forEach(link => {
          link.classList.remove('active');
          const href = link.getAttribute('href');
          if (href.endsWith(`#${activeHeadingId}`)) {
            link.classList.add('active');
          }
        });
      }
    });
  }, options);
  
  headings.forEach(h => scrollSpyObserver.observe(h));
}

// --- Reading Progress Indicator ---
function initReadingProgress() {
  const articleEl = document.getElementById('doc-article');
  const progressBar = document.getElementById('reading-progress-bar');
  
  articleEl.addEventListener('scroll', () => {
    const scrollHeight = articleEl.scrollHeight - articleEl.clientHeight;
    if (scrollHeight > 0) {
      const percentage = (articleEl.scrollTop / scrollHeight) * 100;
      progressBar.style.width = `${percentage}%`;
    } else {
      progressBar.style.width = '0%';
    }
    
    // Back to top button visibility
    const backToTopBtn = document.getElementById('back-to-top-btn');
    if (articleEl.scrollTop > 300) {
      backToTopBtn.classList.add('visible');
    } else {
      backToTopBtn.classList.remove('visible');
    }
  });

  // Back to top click handler
  document.getElementById('back-to-top-btn').addEventListener('click', () => {
    articleEl.scrollTo({ top: 0, behavior: 'smooth' });
  });
}

// --- Document Content Loader ---
function loadDocument(docId, anchorId = null) {
  const doc = getDocById(docId);
  state.currentDocId = doc.id;
  
  // Apply translation and layout
  hydrateUI(doc.metadata.lang);
  
  // Highlight active item in sidebar
  document.querySelectorAll('#document-list .nav-item').forEach(el => el.classList.remove('active'));
  const activeNav = document.getElementById(`nav-item-${doc.id}`);
  if (activeNav) activeNav.classList.add('active');
  
  // Breadcrumbs
  document.getElementById('breadcrumb-current').textContent = doc.title;
  
  // Main Metadata
  document.getElementById('meta-date').textContent = doc.metadata.date || '---';
  document.getElementById('meta-owner').textContent = doc.metadata.owner || '---';
  document.getElementById('meta-time-text').textContent = `${doc.metadata.readingTime} ${uiTranslations[doc.metadata.lang].readTime}`;
  
  const statusEl = document.getElementById('meta-status');
  statusEl.textContent = doc.metadata.status || 'Draft';
  statusEl.className = 'cell-value badge-status'; // reset
  
  const statusText = doc.metadata.status.toLowerCase();
  if (statusText.includes('approved')) statusEl.classList.add('status-approved');
  else if (statusText.includes('idea')) statusEl.classList.add('status-idea');
  else statusEl.classList.add('status-draft');
  
  // Language Badge
  document.getElementById('meta-lang-badge').textContent = doc.metadata.lang.toUpperCase();
  
  // Document Title
  document.getElementById('doc-title').textContent = doc.title;
  
  // Markdown Render
  const renderContainer = document.getElementById('markdown-render');
  renderContainer.className = `markdown-body fade-in-active`;
  
  // Preprocess alerts then parse markdown
  const preprocessed = preprocessMarkdown(doc.content);
  renderContainer.innerHTML = marked.parse(preprocessed);
  
  // Refresh Outline TOC
  renderTOC();
  
  // Scroll to position
  const articleEl = document.getElementById('doc-article');
  if (anchorId) {
    setTimeout(() => {
      const target = document.getElementById(anchorId);
      if (target) {
        target.scrollIntoView({ behavior: 'smooth' });
      } else {
        articleEl.scrollTop = 0;
      }
    }, 100);
  } else {
    articleEl.scrollTop = 0;
  }
  
  // Clean animation class
  setTimeout(() => {
    renderContainer.classList.remove('fade-in-active');
  }, 300);

  // Close mobile sidebar if open
  document.getElementById('sidebar').classList.remove('open');
}

// --- Client-Side Search Engine (Diacritic & Accent Insensitive) ---
function stripArabicDiacritics(text) {
  // Strip Tashkeel (Arabic diacritics) for diacritic-insensitive search matching
  return text.replace(/[\u064B-\u0652\u0670]/g, "");
}

function searchDocs(query) {
  if (!query.trim()) {
    state.searchResults = [];
    renderSearchResults();
    return;
  }
  
  const terms = stripArabicDiacritics(query.toLowerCase()).split(/\s+/).filter(Boolean);
  const results = [];
  
  docsData.forEach(doc => {
    const cleanTitle = stripArabicDiacritics(doc.title.toLowerCase());
    const cleanContent = stripArabicDiacritics(doc.content.toLowerCase());
    
    let score = 0;
    let snippet = "";
    
    // Check Title Match
    const titleMatchCount = terms.reduce((count, term) => {
      return count + (cleanTitle.includes(term) ? 1 : 0);
    }, 0);
    
    if (titleMatchCount === terms.length) {
      score += 100; // full match on title
    } else if (titleMatchCount > 0) {
      score += titleMatchCount * 30; // partial match on title
    }
    
    // Check Content Match
    let firstTermIdx = -1;
    const bodyMatchCount = terms.reduce((count, term) => {
      const idx = cleanContent.indexOf(term);
      if (idx !== -1 && firstTermIdx === -1) {
        firstTermIdx = idx;
      }
      return count + (idx !== -1 ? 1 : 0);
    }, 0);
    
    if (bodyMatchCount > 0) {
      score += bodyMatchCount * 10;
    }
    
    // If we have any score, compile a result item
    if (score > 0) {
      // Find a snippet of text around the match
      if (firstTermIdx !== -1) {
        const start = Math.max(0, firstTermIdx - 30);
        const end = Math.min(doc.content.length, firstTermIdx + 80);
        let excerpt = doc.content.substring(start, end).replace(/\n/g, " ");
        if (start > 0) excerpt = "..." + excerpt;
        if (end < doc.content.length) excerpt = excerpt + "...";
        
        // Highlight terms in excerpt (case-insensitive & diacritic safe)
        // For simplicity in highlight rendering, do a quick highlight replace
        let highlightedExcerpt = excerpt;
        terms.forEach(term => {
          const regex = new RegExp(`(${term})`, 'gi');
          highlightedExcerpt = highlightedExcerpt.replace(regex, '<mark>$1</mark>');
        });
        snippet = highlightedExcerpt;
      } else {
        snippet = doc.content.substring(0, 100).replace(/\n/g, " ") + "...";
      }
      
      results.push({
        doc: doc,
        score: score,
        snippet: snippet
      });
    }
  });
  
  // Sort results by score (descending)
  state.searchResults = results.sort((a, b) => b.score - a.score);
  state.searchSelectedIndex = state.searchResults.length > 0 ? 0 : -1;
  renderSearchResults(query);
}

function renderSearchResults(query = "") {
  const container = document.getElementById('search-results-list');
  const info = document.getElementById('search-results-info');
  
  container.innerHTML = '';
  
  if (!query.trim()) {
    info.textContent = uiTranslations[getDocById(state.currentDocId).metadata.lang].typeToSearch;
    return;
  }
  
  if (state.searchResults.length === 0) {
    info.textContent = `${uiTranslations[getDocById(state.currentDocId).metadata.lang].noResults} "${query}"`;
    return;
  }
  
  info.textContent = `Found ${state.searchResults.length} results:`;
  
  state.searchResults.forEach((result, idx) => {
    const li = document.createElement('li');
    li.className = `search-result-item ${idx === state.searchSelectedIndex ? 'selected' : ''}`;
    li.innerHTML = `
      <div class="search-result-title">
        <span>${result.doc.title}</span>
        <span class="search-result-lang">${result.doc.metadata.lang.toUpperCase()}</span>
      </div>
      <div class="search-result-snippet">${result.snippet}</div>
    `;
    
    li.addEventListener('click', () => {
      window.location.hash = `#docs/${result.doc.id}`;
      closeSearchModal();
    });
    
    container.appendChild(li);
  });
}

// --- Search Modal Toggle Actions ---
function openSearchModal() {
  const modal = document.getElementById('search-modal');
  modal.style.display = 'flex';
  const input = document.getElementById('search-input');
  input.value = '';
  input.focus();
  searchDocs('');
}

function closeSearchModal() {
  const modal = document.getElementById('search-modal');
  modal.style.display = 'none';
}

function initSearchControls() {
  // Button Triggers
  document.getElementById('search-trigger-btn').addEventListener('click', openSearchModal);
  document.getElementById('search-close-btn').addEventListener('click', closeSearchModal);
  
  // Close on outside card click
  document.getElementById('search-modal').addEventListener('click', (e) => {
    if (e.target.id === 'search-modal') closeSearchModal();
  });
  
  // Search key input listeners
  const input = document.getElementById('search-input');
  input.addEventListener('input', (e) => {
    searchDocs(e.target.value);
  });
  
  // Hotkeys & Navigation
  window.addEventListener('keydown', (e) => {
    // CMD+K or CTRL+K or / to open search (unless typing in inputs)
    if ((e.metaKey && e.key === 'k') || (e.ctrlKey && e.key === 'k') || (e.key === '/' && document.activeElement.tagName !== 'INPUT' && document.activeElement.tagName !== 'TEXTAREA')) {
      e.preventDefault();
      openSearchModal();
    }
    
    // Actions when search is visible
    const modal = document.getElementById('search-modal');
    if (modal.style.display === 'flex') {
      if (e.key === 'Escape') {
        closeSearchModal();
      } else if (e.key === 'ArrowDown') {
        e.preventDefault();
        if (state.searchResults.length > 0) {
          state.searchSelectedIndex = (state.searchSelectedIndex + 1) % state.searchResults.length;
          renderSearchResults(input.value);
          scrollSelectedSearchResultIntoView();
        }
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        if (state.searchResults.length > 0) {
          state.searchSelectedIndex = (state.searchSelectedIndex - 1 + state.searchResults.length) % state.searchResults.length;
          renderSearchResults(input.value);
          scrollSelectedSearchResultIntoView();
        }
      } else if (e.key === 'Enter') {
        e.preventDefault();
        if (state.searchSelectedIndex !== -1 && state.searchResults[state.searchSelectedIndex]) {
          const selectedDoc = state.searchResults[state.searchSelectedIndex].doc;
          window.location.hash = `#docs/${selectedDoc.id}`;
          closeSearchModal();
        }
      }
    }
  });
}

function scrollSelectedSearchResultIntoView() {
  const selectedNode = document.querySelector('.search-result-item.selected');
  if (selectedNode) {
    selectedNode.scrollIntoView({ block: 'nearest' });
  }
}

// --- Mobile Navigation Drawer Toggles ---
function initMobileNavigation() {
  const toggleBtn = document.getElementById('mobile-menu-toggle');
  const sidebar = document.getElementById('sidebar');
  
  toggleBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    sidebar.classList.toggle('open');
  });
  
  // Close sidebar clicking outside
  document.addEventListener('click', (e) => {
    if (!sidebar.contains(e.target) && e.target !== toggleBtn) {
      sidebar.classList.remove('open');
    }
  });
}

// --- SPA Router ---
function router() {
  const hash = window.location.hash;
  
  // Patterns: 
  // #docs/file-id
  // #docs/file-id#header-id
  let docId = 'README';
  let anchorId = null;
  
  if (hash) {
    const parts = hash.replace(/^#/, '').split('/');
    if (parts[0] === 'docs' && parts[1]) {
      const docParts = parts[1].split('#');
      docId = docParts[0];
      if (docParts[1]) anchorId = decodeURIComponent(docParts[1]);
    }
  }
  
  loadDocument(docId, anchorId);
}

// --- Screen Size Resize Handler ---
window.addEventListener('resize', () => {
  // Re-evaluate TOC side pane visibility on resize
  const tocPanel = document.getElementById('toc-panel');
  if (tocPanel) {
    const headings = document.querySelectorAll('#markdown-render h2, #markdown-render h3');
    tocPanel.style.display = (window.innerWidth > 1024 && headings.length > 0) ? 'block' : 'none';
  }
});

// --- App Initialization ---
window.addEventListener('DOMContentLoaded', () => {
  setupMarkedRenderer();
  initTheme();
  renderSidebar();
  initReadingProgress();
  initSearchControls();
  initMobileNavigation();
  
  // Run router initially
  router();
  window.addEventListener('hashchange', router);
});
