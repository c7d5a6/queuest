

export const index = 2;
let component_cache;
export const component = async () => component_cache ??= (await import('../entries/pages/_page.svelte.js')).default;
export const imports = ["_app/immutable/nodes/2.efb5a4e6.js","_app/immutable/chunks/scheduler.a390f69a.js","_app/immutable/chunks/index.7cdb3e14.js"];
export const stylesheets = [];
export const fonts = [];
