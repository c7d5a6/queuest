

export const index = 1;
let component_cache;
export const component = async () => component_cache ??= (await import('../entries/fallbacks/error.svelte.js')).default;
export const imports = ["_app/immutable/nodes/1.77e02489.js","_app/immutable/chunks/scheduler.a390f69a.js","_app/immutable/chunks/index.7cdb3e14.js","_app/immutable/chunks/singletons.eb1278d1.js"];
export const stylesheets = [];
export const fonts = [];
