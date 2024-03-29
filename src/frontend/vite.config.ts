import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import * as fs from "fs";

const isDev = process.env["DFX_NETWORK"] !== "ic";

let canisterIds;

try {
	canisterIds = JSON.parse(
		fs
			.readFileSync(
				isDev ? "../../.dfx/local/canister_ids.json" : "../../canister_ids.json"
			)
			.toString()
	);
} catch (e) {}

const canisterDefinitions = Object.entries(canisterIds).reduce(
	(acc, [key, val]: any) => {
		return {
			...acc,
			[`process.env.${key.toUpperCase()}_CANISTER_ID`]: isDev
				? JSON.stringify(val.local)
				: JSON.stringify(val.ic),
		};
	},
	{}
);

const DFX_PORT = 8000;

export default defineConfig({

  define: {
		// Here we can define global constants
		// This is required for now because the code generated by dfx relies on process.env being set
		...canisterDefinitions,
		"process.env.NODE_ENV": JSON.stringify(
			isDev ? "development" : "production"
		),
	},

	optimizeDeps: {
		exclude: [],
	},
	
  plugins: [react()],
	
  root: "",

	resolve: {
		alias: {},
	},

	server: {
		fs: {
			// allow: ["."],
		},

		proxy: {
			"/api": {
				target: isDev ? `http://localhost:${DFX_PORT}` : `https://ic0.app`,
				changeOrigin: true,
				secure: isDev ? false : true,
				//rewrite: (path) => path.replace(/^\/api/, "/api"),
			},
		},
	},

	// add build version
});