/* ============================================================================
   SmartBunda — Presentation interactions
   Vanilla JS, no dependencies. Progressive-enhancement: the page is fully
   readable without JS; this just adds motion, scroll-spy, counters, and the
   mobile menu.
   ----------------------------------------------------------------------------
   Modules:
     1. prefers-reduced-motion guard
     2. Scroll-reveal (IntersectionObserver)
     3. Animated number counters
     4. Navbar: shadow on scroll + active-section spy
     5. Mobile menu toggle
     6. Current year in footer
   ========================================================================== */
(function () {
  "use strict";

  // 1. Reduced-motion guard ---------------------------------------------------
  const prefersReducedMotion = window.matchMedia(
    "(prefers-reduced-motion: reduce)"
  ).matches;

  // 2. Scroll-reveal ----------------------------------------------------------
  const revealEls = document.querySelectorAll(".reveal");

  if (prefersReducedMotion || !("IntersectionObserver" in window)) {
    // Show everything immediately; no motion.
    revealEls.forEach((el) => el.classList.add("is-visible"));
  } else {
    const revealObserver = new IntersectionObserver(
      (entries, observer) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            observer.unobserve(entry.target); // reveal once, then stop watching
          }
        });
      },
      { threshold: 0.15, rootMargin: "0px 0px -8% 0px" }
    );
    revealEls.forEach((el) => revealObserver.observe(el));
  }

  // 3. Animated counters ------------------------------------------------------
  // Each [data-count] animates from 0 to its target when first scrolled into view.
  const counters = document.querySelectorAll("[data-count]");

  function animateCount(el) {
    const target = parseFloat(el.dataset.count);
    const decimals = (el.dataset.decimals && parseInt(el.dataset.decimals)) || 0;
    const duration = 1600;
    const start = performance.now();

    function tick(now) {
      const progress = Math.min((now - start) / duration, 1);
      // easeOutCubic for a premium settle
      const eased = 1 - Math.pow(1 - progress, 3);
      const value = target * eased;
      el.textContent = value.toFixed(decimals);
      if (progress < 1) requestAnimationFrame(tick);
      else el.textContent = target.toFixed(decimals);
    }
    requestAnimationFrame(tick);
  }

  if (counters.length) {
    if (prefersReducedMotion || !("IntersectionObserver" in window)) {
      counters.forEach((el) => {
        const decimals =
          (el.dataset.decimals && parseInt(el.dataset.decimals)) || 0;
        el.textContent = parseFloat(el.dataset.count).toFixed(decimals);
      });
    } else {
      const countObserver = new IntersectionObserver(
        (entries, observer) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              animateCount(entry.target);
              observer.unobserve(entry.target);
            }
          });
        },
        { threshold: 0.6 }
      );
      counters.forEach((el) => countObserver.observe(el));
    }
  }

  // 4. Navbar: shadow on scroll + scroll-spy ---------------------------------
  const nav = document.querySelector(".nav");
  const navLinks = Array.from(document.querySelectorAll(".nav__link"));
  const sections = navLinks
    .map((link) => document.querySelector(link.getAttribute("href")))
    .filter(Boolean);

  // Reading-progress bar + back-to-top: updated together on scroll.
  const progressBar = document.getElementById("progressBar");
  const toTop = document.getElementById("toTop");

  function onScroll() {
    const y = window.scrollY;
    if (nav) nav.classList.toggle("is-scrolled", y > 24);

    // Progress = how far through the whole document we've scrolled (0–100%).
    if (progressBar) {
      const doc = document.documentElement;
      const scrollable = doc.scrollHeight - doc.clientHeight;
      const pct = scrollable > 0 ? (y / scrollable) * 100 : 0;
      progressBar.style.width = pct + "%";
    }

    // Reveal the back-to-top button once the visitor has scrolled a screenful.
    if (toTop) toTop.classList.toggle("is-shown", y > window.innerHeight * 0.8);
  }
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  // Back-to-top click → smooth scroll to the top (respects reduced motion).
  if (toTop) {
    toTop.addEventListener("click", () => {
      window.scrollTo({
        top: 0,
        behavior: prefersReducedMotion ? "auto" : "smooth",
      });
    });
  }

  // Highlight the nav link of the section currently in view.
  if (sections.length && "IntersectionObserver" in window) {
    const spy = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const id = "#" + entry.target.id;
            navLinks.forEach((link) =>
              link.classList.toggle(
                "is-active",
                link.getAttribute("href") === id
              )
            );
          }
        });
      },
      { rootMargin: "-45% 0px -50% 0px", threshold: 0 }
    );
    sections.forEach((sec) => spy.observe(sec));
  }

  // 5. Mobile menu toggle -----------------------------------------------------
  const toggle = document.querySelector(".nav__toggle");
  const linksWrap = document.querySelector(".nav__links");

  if (toggle && linksWrap) {
    toggle.addEventListener("click", () => {
      const open = linksWrap.classList.toggle("is-open");
      toggle.setAttribute("aria-expanded", String(open));
    });
    // Close the menu after tapping a link (mobile).
    linksWrap.addEventListener("click", (e) => {
      if (e.target.closest(".nav__link")) {
        linksWrap.classList.remove("is-open");
        toggle.setAttribute("aria-expanded", "false");
      }
    });
  }

  // 6. Keyboard navigation + slide counter ------------------------------------
  // Treats each <main> > section as a "slide". Arrow / Page / Home / End keys
  // jump between them, and a fixed counter shows the current slide (e.g. 03/10).
  const slides = Array.from(document.querySelectorAll("main > section"));
  const counter = document.getElementById("slideCounter");
  const curEl = document.getElementById("slideCurrent");
  const totalEl = document.getElementById("slideTotal");
  let activeSlide = 0;

  const pad = (n) => String(n).padStart(2, "0");

  if (slides.length) {
    if (totalEl) totalEl.textContent = pad(slides.length);

    // Track which slide is centred in the viewport → update the counter.
    if ("IntersectionObserver" in window) {
      const slideSpy = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              activeSlide = slides.indexOf(entry.target);
              if (curEl) curEl.textContent = pad(activeSlide + 1);
            }
          });
        },
        { threshold: 0.5 }
      );
      slides.forEach((s) => slideSpy.observe(s));
    }

    // Show the counter only after leaving the hero (keeps the hero clean).
    window.addEventListener(
      "scroll",
      () => {
        if (counter)
          counter.classList.toggle(
            "is-shown",
            window.scrollY > window.innerHeight * 0.5
          );
      },
      { passive: true }
    );

    // Jump to a slide by index, clamped to range.
    function goToSlide(index) {
      const i = Math.max(0, Math.min(slides.length - 1, index));
      slides[i].scrollIntoView({
        behavior: prefersReducedMotion ? "auto" : "smooth",
        block: "start",
      });
    }

    // Keyboard controls — ignored while typing in a field.
    document.addEventListener("keydown", (e) => {
      const tag = (e.target.tagName || "").toLowerCase();
      if (tag === "input" || tag === "textarea" || e.target.isContentEditable)
        return;

      switch (e.key) {
        case "ArrowDown":
        case "PageDown":
          e.preventDefault();
          goToSlide(activeSlide + 1);
          break;
        case "ArrowUp":
        case "PageUp":
          e.preventDefault();
          goToSlide(activeSlide - 1);
          break;
        case "Home":
          e.preventDefault();
          goToSlide(0);
          break;
        case "End":
          e.preventDefault();
          goToSlide(slides.length - 1);
          break;
      }
    });
  }

  // 7. Footer year ------------------------------------------------------------
  const yearEl = document.getElementById("year");
  if (yearEl) yearEl.textContent = new Date().getFullYear();
})();
