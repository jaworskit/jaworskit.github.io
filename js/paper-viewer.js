/* paper-viewer.js — shared interactive paper viewer behaviour */
(function() {
  'use strict';

  var SCROLL_OFFSET = 16;

  // ── Helpers ─────────────────────────────────────

  function toggleSection(btn, open) {
    var bodyId = btn.getAttribute('aria-controls');
    var body = document.getElementById(bodyId);
    if (!body) return;
    btn.setAttribute('aria-expanded', open);
    var icon = btn.querySelector('.pv-toggle-icon');
    if (icon) icon.innerHTML = open ? '\u25BC' : '\u25B6';
    if (open) {
      body.removeAttribute('hidden');
      // Re-render MathJax in newly revealed content
      if (window.MathJax && MathJax.typesetPromise) {
        MathJax.typesetPromise([body]).catch(function() {});
      }
    } else {
      body.setAttribute('hidden', '');
    }
  }

  function expandSectionContaining(el) {
    var section = el.closest('.pv-section');
    if (section) {
      var btn = section.querySelector('.pv-toggle');
      if (btn && btn.getAttribute('aria-expanded') !== 'true') {
        toggleSection(btn, true);
      }
    }
  }

  function smoothScroll(el, block) {
    block = block || 'start';
    setTimeout(function() {
      var y = el.getBoundingClientRect().top + window.pageYOffset - SCROLL_OFFSET;
      if (block === 'center') {
        y = el.getBoundingClientRect().top + window.pageYOffset
            - window.innerHeight / 2 + el.offsetHeight / 2;
      }
      window.scrollTo({ top: y, behavior: 'smooth' });
    }, 60);
  }

  function pushHash(hash) {
    if (history.pushState) {
      history.pushState(null, '', hash);
    }
  }

  // ── Section toggle buttons ──────────────────────

  document.querySelectorAll('.pv-toggle').forEach(function(btn) {
    btn.addEventListener('click', function() {
      var expanded = btn.getAttribute('aria-expanded') === 'true';
      toggleSection(btn, !expanded);
    });
  });

  // ── Expand All / Collapse All ───────────────────

  var expandBtn = document.getElementById('pv-expand-all');
  if (expandBtn) {
    expandBtn.addEventListener('click', function() {
      var allExpanded = true;
      document.querySelectorAll('.pv-toggle').forEach(function(btn) {
        if (btn.getAttribute('aria-expanded') !== 'true') allExpanded = false;
      });
      document.querySelectorAll('.pv-toggle').forEach(function(btn) {
        toggleSection(btn, !allExpanded);
      });
      expandBtn.textContent = allExpanded ? 'Expand all sections' : 'Collapse all sections';
    });
  }

  // ── TOC click-to-expand & scroll ────────────────

  document.querySelectorAll('.pv-toc-link').forEach(function(link) {
    link.addEventListener('click', function(e) {
      e.preventDefault();
      var targetId = link.getAttribute('href').slice(1);
      var section = document.getElementById(targetId);
      if (!section) return;

      var btn = section.querySelector('.pv-toggle');
      if (btn && btn.getAttribute('aria-expanded') !== 'true') {
        toggleSection(btn, true);
      }
      pushHash('#' + targetId);
      smoothScroll(section, 'start');
    });
  });

  // ── Footnote links: expand Footnotes & scroll ───

  document.querySelectorAll('.pv-fn-ref').forEach(function(link) {
    link.addEventListener('click', function(e) {
      e.preventDefault();
      var fnSection = document.getElementById('footnotes');
      if (fnSection) {
        var btn = fnSection.querySelector('.pv-toggle');
        if (btn && btn.getAttribute('aria-expanded') !== 'true') {
          toggleSection(btn, true);
        }
      }
      var targetId = link.getAttribute('href').slice(1);
      var target = document.getElementById(targetId);
      if (target) {
        pushHash('#' + targetId);
        smoothScroll(target, 'center');
      }
    });
  });

  // ── Footnote back-links: expand parent section ──

  document.querySelectorAll('.pv-fn-back').forEach(function(link) {
    link.addEventListener('click', function(e) {
      e.preventDefault();
      var targetId = link.getAttribute('href').slice(1);
      var target = document.getElementById(targetId);
      if (target) {
        expandSectionContaining(target);
        pushHash('#' + targetId);
        smoothScroll(target, 'center');
      }
    });
  });

  // ── Citation links: expand References & scroll ──

  document.querySelectorAll('.pv-cite').forEach(function(link) {
    var href = link.getAttribute('href');
    if (href && href.startsWith('#ref-')) {
      link.addEventListener('click', function(e) {
        e.preventDefault();
        var refSection = document.getElementById('references');
        if (refSection) {
          var btn = refSection.querySelector('.pv-toggle');
          if (btn && btn.getAttribute('aria-expanded') !== 'true') {
            toggleSection(btn, true);
          }
        }
        var targetId = href.slice(1);
        var target = document.getElementById(targetId);
        if (target) {
          pushHash('#' + targetId);
          smoothScroll(target, 'center');
        }
      });
    }
  });

  // ── Browser back/forward: expand target section ─

  window.addEventListener('popstate', function() {
    var hash = window.location.hash;
    if (!hash) return;
    var target = document.getElementById(hash.slice(1));
    if (target) {
      expandSectionContaining(target);
      smoothScroll(target, 'center');
    }
  });

  // ── TOC active state (scroll-based) ─────────────

  var tocLinks = document.querySelectorAll('.pv-toc-link');
  var sectionEls = [];
  tocLinks.forEach(function(link) {
    var id = link.getAttribute('href').slice(1);
    var el = document.getElementById(id);
    if (el) sectionEls.push({ el: el, link: link });
  });

  function updateTocActive() {
    var current = null;
    var scrollY = window.pageYOffset + SCROLL_OFFSET + 60;
    for (var i = sectionEls.length - 1; i >= 0; i--) {
      if (sectionEls[i].el.offsetTop <= scrollY) {
        current = sectionEls[i];
        break;
      }
    }
    if (current) {
      tocLinks.forEach(function(l) { l.classList.remove('pv-toc-active'); });
      current.link.classList.add('pv-toc-active');
    }
  }

  var ticking = false;
  window.addEventListener('scroll', function() {
    if (!ticking) {
      requestAnimationFrame(function() { updateTocActive(); ticking = false; });
      ticking = true;
    }
  });
  updateTocActive();

  // ── Figure tabs ──────────────────────────────────

  document.querySelectorAll('.pv-figure').forEach(function(fig) {
    var tabs = fig.querySelectorAll('.pv-figure-tab');
    var panels = fig.querySelectorAll('.pv-figure-panel');
    tabs.forEach(function(tab) {
      tab.addEventListener('click', function() {
        var idx = parseInt(tab.getAttribute('data-panel'), 10);
        tabs.forEach(function(t) { t.classList.remove('pv-tab-active'); });
        panels.forEach(function(p) { p.classList.remove('pv-panel-active'); });
        tab.classList.add('pv-tab-active');
        if (panels[idx]) panels[idx].classList.add('pv-panel-active');
      });
    });
  });

  // ── Lightbox ────────────────────────────────────

  var lightbox = document.getElementById('pv-lightbox');
  var lightboxImg = lightbox ? lightbox.querySelector('img') : null;

  document.querySelectorAll('.pv-figure-panel img').forEach(function(img) {
    img.addEventListener('click', function() {
      if (lightbox && lightboxImg) {
        lightboxImg.src = img.src;
        lightboxImg.alt = img.alt;
        lightbox.classList.add('pv-lightbox-open');
        lightbox.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden';
      }
    });
  });

  function closeLightbox() {
    if (lightbox) {
      lightbox.classList.remove('pv-lightbox-open');
      lightbox.setAttribute('aria-hidden', 'true');
      document.body.style.overflow = '';
    }
  }

  if (lightbox) {
    lightbox.addEventListener('click', closeLightbox);
    var closeBtn = lightbox.querySelector('.pv-lightbox-close');
    if (closeBtn) closeBtn.addEventListener('click', closeLightbox);
  }

  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeLightbox();
  });

})();
