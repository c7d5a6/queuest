export const manifest = (() => {
function __memo(fn) {
	let value;
	return () => value ??= (value = fn());
}

return {
	appDir: "_app",
	appPath: "_app",
	assets: new Set(["favicon.png"]),
	mimeTypes: {".png":"image/png"},
	_: {
		client: {"start":"_app/immutable/entry/start.999ede6d.js","app":"_app/immutable/entry/app.5e0ae694.js","imports":["_app/immutable/entry/start.999ede6d.js","_app/immutable/chunks/scheduler.a390f69a.js","_app/immutable/chunks/singletons.eb1278d1.js","_app/immutable/entry/app.5e0ae694.js","_app/immutable/chunks/scheduler.a390f69a.js","_app/immutable/chunks/index.7cdb3e14.js"],"stylesheets":[],"fonts":[]},
		nodes: [
			__memo(() => import('./nodes/0.js')),
			__memo(() => import('./nodes/1.js')),
			__memo(() => import('./nodes/2.js'))
		],
		routes: [
			{
				id: "/",
				pattern: /^\/$/,
				params: [],
				page: { layouts: [0,], errors: [1,], leaf: 2 },
				endpoint: null
			}
		],
		matchers: async () => {
			
			return {  };
		}
	}
}
})();
