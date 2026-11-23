(() => {
  "use strict";

  const root = document.documentElement;
  const themeButton = document.getElementById("theme-switch");
  const themeText = themeButton?.querySelector(".theme-text");
  const themeModes = ["auto", "light", "dark"];
  const safeStorage = {
    get() { try { return localStorage.getItem("nova-browser-theme"); } catch (_) { return null; } },
    set(value) { try { localStorage.setItem("nova-browser-theme", value); } catch (_) {} }
  };

  function applyTheme(mode) {
    const selected = themeModes.includes(mode) ? mode : "auto";
    if (selected === "auto") root.removeAttribute("data-theme");
    else root.setAttribute("data-theme", selected);
    if (themeText) themeText.textContent = selected[0].toUpperCase() + selected.slice(1);
    if (themeButton) {
      themeButton.setAttribute("aria-label", "Theme: " + selected + ". Change theme");
      themeButton.title = "Appearance: " + selected + " (click to change)";
      themeButton.dataset.mode = selected;
    }
    const dark = selected === "dark" || (selected === "auto" && window.matchMedia("(prefers-color-scheme: dark)").matches);
    document.querySelector('meta[name="theme-color"]')?.setAttribute("content", dark ? "#17191b" : "#f8f8f6");
    return selected;
  }

  let currentMode = applyTheme(safeStorage.get() || "auto");
  themeButton?.addEventListener("click", () => {
    currentMode = applyTheme(themeModes[(themeModes.indexOf(currentMode) + 1) % themeModes.length]);
    safeStorage.set(currentMode);
  });
  const systemScheme = window.matchMedia("(prefers-color-scheme: dark)");
  if (systemScheme.addEventListener) systemScheme.addEventListener("change", () => { if (currentMode === "auto") applyTheme("auto"); });

  const menuButton = document.getElementById("menu-button");
  const navLinks = document.getElementById("nav-links");
  function closeMenu() {
    navLinks?.classList.remove("open");
    menuButton?.setAttribute("aria-expanded", "false");
    menuButton?.setAttribute("aria-label", "Open menu");
  }
  menuButton?.addEventListener("click", () => {
    const opened = menuButton.getAttribute("aria-expanded") !== "true";
    navLinks?.classList.toggle("open", opened);
    menuButton.setAttribute("aria-expanded", String(opened));
    menuButton.setAttribute("aria-label", opened ? "Close menu" : "Open menu");
  });
  navLinks?.querySelectorAll("a").forEach(link => link.addEventListener("click", closeMenu));
  document.addEventListener("keydown", event => {
    if (event.key === "Escape" && menuButton?.getAttribute("aria-expanded") === "true") {
      closeMenu();
      menuButton.focus();
    }
  });
  document.addEventListener("pointerdown", event => {
    if (menuButton && navLinks && !menuButton.contains(event.target) && !navLinks.contains(event.target)) closeMenu();
  });

  const header = document.querySelector(".site-header");
  function onScroll() { header?.classList.toggle("scrolled", window.scrollY > 12); }
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
  const revealItems = document.querySelectorAll(".reveal");
  if (!("IntersectionObserver" in window) || reducedMotion.matches) {
    revealItems.forEach(item => item.classList.add("visible"));
  } else {
    const observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add("visible");
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.08, rootMargin: "0px 0px -35px 0px" });
    revealItems.forEach(item => observer.observe(item));
  }

  // The preview search form uses standard GET navigation to search.html.
  // No JavaScript interception: keyboard and assistive-tech form submission works.

  const year = document.getElementById("year");
  if (year) year.textContent = String(new Date().getFullYear());

  // Update active navigation links as sections enter view.
  const anchors = Array.from(document.querySelectorAll('.nav-links a[href^="#"]'));
  const sections = anchors.map(a => document.querySelector(a.getAttribute("href"))).filter(Boolean);
  if ("IntersectionObserver" in window && sections.length) {
    const activeObserver = new IntersectionObserver(entries => {
      const visible = entries.filter(entry => entry.isIntersecting).sort((a, b) => b.intersectionRatio - a.intersectionRatio);
      if (!visible.length) return;
      const id = "#" + visible[0].target.id;
      anchors.forEach(link => {
        const active = link.getAttribute("href") === id;
        link.classList.toggle("active", active);
        if (active) link.setAttribute("aria-current", "location");
        else link.removeAttribute("aria-current");
      });
    }, { rootMargin: "-10% 0px -58% 0px", threshold: [0, 0.3, 0.6] });
    sections.forEach(section => activeObserver.observe(section));
  }
})();