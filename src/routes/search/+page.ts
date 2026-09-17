import type { SearchDoc } from '../search-index.json/+server';

export const prerender = false;

export async function load({ fetch }) {
	const res = await fetch('/search-index.json');
	const docs: SearchDoc[] = res.ok ? await res.json() : [];
	return { docs };
}
