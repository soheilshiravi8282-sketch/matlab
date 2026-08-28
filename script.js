(() => {
  'use strict';

  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (window.gsap && window.ScrollTrigger) gsap.registerPlugin(ScrollTrigger);

  /* ---------------------------------------------------------------------
     Custom cursor — stays hidden until the first real mouse movement,
     so there is never a stray dot sitting at 0,0 before the user moves.
  --------------------------------------------------------------------- */
  const cursor = document.querySelector('.cursor');
  if (cursor && window.matchMedia('(hover: hover) and (pointer: fine)').matches) {
    let hasMoved = false;
    window.addEventListener('mousemove', (e) => {
      cursor.style.transform = `translate(${e.clientX}px, ${e.clientY}px)`;
      if (!hasMoved) {
        hasMoved = true;
        cursor.classList.add('is-visible');
      }
    }, { passive: true });

    document.querySelectorAll('[data-cursor]').forEach((el) => {
      el.addEventListener('mouseenter', () => cursor.classList.add('is-active'));
      el.addEventListener('mouseleave', () => cursor.classList.remove('is-active'));
    });
    window.addEventListener('mouseleave', () => cursor.classList.remove('is-visible'));
    window.addEventListener('mouseenter', () => { if (hasMoved) cursor.classList.add('is-visible'); });
  }

  /* ---------------------------------------------------------------------
     Scroll progress rail
  --------------------------------------------------------------------- */
  const fill = document.querySelector('.progress-rail__fill');
  function updateProgress() {
    const h = document.documentElement;
    const scrolled = h.scrollTop;
    const max = h.scrollHeight - h.clientHeight;
    const pct = max > 0 ? (scrolled / max) * 100 : 0;
    if (fill) fill.style.height = pct + '%';
  }
  document.addEventListener('scroll', updateProgress, { passive: true });
  updateProgress();

  /* ---------------------------------------------------------------------
     Mobile nav toggle
  --------------------------------------------------------------------- */
  const burger = document.getElementById('burgerBtn');
  const navMenu = document.getElementById('navMenu');
  if (burger && navMenu) {
    burger.addEventListener('click', () => {
      const open = navMenu.classList.toggle('is-open');
      burger.setAttribute('aria-expanded', String(open));
    });
    navMenu.querySelectorAll('a').forEach((a) => {
      a.addEventListener('click', () => {
        navMenu.classList.remove('is-open');
        burger.setAttribute('aria-expanded', 'false');
      });
    });
  }

  /* ---------------------------------------------------------------------
     Hero blueprint: draw-on animation for the SVG elevation, plus a
     slow parallax drift of the grid layer as the user scrolls.
  --------------------------------------------------------------------- */
  const drawPaths = document.querySelectorAll('.hero__elevation .draw');
  drawPaths.forEach((el) => {
    try {
      const len = el.getTotalLength ? el.getTotalLength() : 400;
      el.style.strokeDasharray = len;
      el.style.strokeDashoffset = reduceMotion ? 0 : len;
    } catch (e) { /* group elements without getTotalLength are ignored */ }
  });

  function playHeroDraw() {
    if (!window.gsap) {
      // Graceful fallback if GSAP failed to load: reveal everything via CSS transitions instead.
      drawPaths.forEach((el) => { el.style.transition = 'stroke-dashoffset 1.1s ease-out'; el.style.strokeDashoffset = 0; });
      document.querySelector('.dims-label').style.transition = 'opacity 0.6s ease';
      document.querySelector('.dims-label').style.opacity = 1;
      document.querySelectorAll('.hero__top, .hero__title, .hero__row > *').forEach((el) => {
        el.style.transition = 'opacity 0.8s ease, transform 0.8s ease';
        el.style.opacity = 1;
        el.style.transform = 'none';
      });
      return;
    }
    const tl = gsap.timeline({ delay: reduceMotion ? 0 : 0.3 });
    drawPaths.forEach((el, i) => {
      const delay = reduceMotion ? 0 : (parseInt(el.dataset.delay, 10) || i * 120) / 1000;
      tl.to(el, { strokeDashoffset: 0, duration: reduceMotion ? 0.01 : 1.1, ease: 'power2.inOut' }, delay);
    });
    tl.to('.dims-label', { opacity: 1, duration: 0.4 }, reduceMotion ? 0 : 1.0);
    gsap.from('.hero__top', { opacity: 0, y: 14, duration: 0.8, ease: 'power2.out', delay: reduceMotion ? 0 : 0.2 });
    gsap.from('.hero__title', { opacity: 0, y: 26, duration: 1, ease: 'power3.out', delay: reduceMotion ? 0 : 0.35 });
    gsap.from('.hero__row > *', { opacity: 0, y: 16, duration: 0.9, ease: 'power2.out', stagger: 0.12, delay: reduceMotion ? 0 : 0.55 });
  }
  playHeroDraw();

  if (!reduceMotion) {
    const grid = document.querySelector('.hero__grid');
    window.addEventListener('scroll', () => {
      const y = window.scrollY * 0.08;
      if (grid) grid.style.transform = `translateY(${y}px)`;
    }, { passive: true });
  }

  /* ---------------------------------------------------------------------
     Generic scroll reveal for section blocks
  --------------------------------------------------------------------- */
  const revealTargets = document.querySelectorAll(
    '.about__text, .about__diagram, .stat, .service-card, .team-card, .process__step, .outro__inner > *'
  );
  revealTargets.forEach((el) => el.classList.add('reveal'));

  const io = new IntersectionObserver((entries) => {
    entries.forEach((entry, idx) => {
      if (entry.isIntersecting) {
        const el = entry.target;
        const group = el.parentElement;
        const siblings = group ? Array.from(group.children).filter((c) => c.classList.contains('reveal')) : [el];
        const order = siblings.indexOf(el);
        el.style.transitionDelay = reduceMotion ? '0ms' : `${Math.max(order, 0) * 90}ms`;
        el.classList.add('is-visible');
        io.unobserve(el);
      }
    });
  }, { threshold: 0.15, rootMargin: '0px 0px -60px 0px' });
  revealTargets.forEach((el) => io.observe(el));

  /* ---------------------------------------------------------------------
     About diagram: draw the floor-plan line once visible
  --------------------------------------------------------------------- */
  const diagramPlan = document.querySelector('.diagram-plan');
  const diagramDots = document.querySelectorAll('.diagram-dot circle');
  if (diagramPlan) {
    const diagramIO = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          if (window.gsap) {
            gsap.to(diagramPlan, { strokeDashoffset: 0, duration: reduceMotion ? 0.01 : 2.2, ease: 'power2.inOut' });
            gsap.to(diagramDots, { opacity: 1, duration: 0.6, delay: reduceMotion ? 0 : 1.8, stagger: 0.15 });
          } else {
            diagramPlan.style.transition = 'stroke-dashoffset 1.8s ease-out';
            diagramPlan.style.strokeDashoffset = '0';
            diagramDots.forEach((d) => { d.style.transition = 'opacity 0.6s ease'; d.style.opacity = 1; });
          }
          diagramIO.unobserve(entry.target);
        }
      });
    }, { threshold: 0.4 });
    diagramIO.observe(diagramPlan);
  }

  /* ---------------------------------------------------------------------
     Animated stat counters
  --------------------------------------------------------------------- */
  const statEls = document.querySelectorAll('.stat__num');
  const toPersianDigits = (n) => String(n).replace(/[0-9]/g, (d) => '۰۱۲۳۴۵۶۷۸۹'[d]);

  function animateCount(el) {
    const target = parseInt(el.dataset.count, 10) || 0;
    const suffix = el.dataset.suffix || '';
    const duration = reduceMotion ? 10 : 1400;
    const start = performance.now();
    function tick(now) {
      const p = Math.min((now - start) / duration, 1);
      const eased = 1 - Math.pow(1 - p, 3);
      const val = Math.round(target * eased);
      el.textContent = toPersianDigits(val) + suffix;
      if (p < 1) requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);
  }

  const statIO = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        animateCount(entry.target);
        statIO.unobserve(entry.target);
      }
    });
  }, { threshold: 0.6 });
  statEls.forEach((el) => statIO.observe(el));

  /* ---------------------------------------------------------------------
     Marquee — duplicate track content once for a seamless CSS loop
  --------------------------------------------------------------------- */
  const track = document.getElementById('marqueeTrack');
  if (track && !reduceMotion) {
    track.innerHTML += track.innerHTML;
    let x = 0;
    let paused = false;
    track.addEventListener('mouseenter', () => (paused = true));
    track.addEventListener('mouseleave', () => (paused = false));
    function loop() {
      if (!paused) {
        x -= 0.5;
        const halfWidth = track.scrollWidth / 2;
        if (Math.abs(x) >= halfWidth) x = 0;
        track.style.transform = `translateX(${x}px)`;
      }
      requestAnimationFrame(loop);
    }
    requestAnimationFrame(loop);
  }

  /* ---------------------------------------------------------------------
     Process rail: light up each step's dot as it enters view
  --------------------------------------------------------------------- */
  const steps = document.querySelectorAll('.process__step');
  const stepIO = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) entry.target.classList.add('is-active');
    });
  }, { threshold: 0.5 });
  steps.forEach((el) => stepIO.observe(el));

})();
