

export const index = 0;
let component_cache;
export const component = async () => component_cache ??= (await import('../entries/pages/_layout.svelte.js')).default;
export const imports = ["_app/immutable/nodes/0.4646d593.js","_app/immutable/chunks/scheduler.a390f69a.js","_app/immutable/chunks/index.7cdb3e14.js"];
export const stylesheets = [];
export const fonts = [];
