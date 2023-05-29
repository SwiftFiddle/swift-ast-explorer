"use strict";

export function throttle(fn) {
  let raf;

  return (...args) => {
    if (raf) {
      cancelAnimationFrame(raf);
      return;
    }

    raf = requestAnimationFrame(() => {
      fn(...args);
      raf = undefined;
    });
  };
}
