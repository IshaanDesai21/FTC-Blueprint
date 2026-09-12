import { redirect } from '@sveltejs/kit';

// The docs index lives at the site root; /software is kept as a redirect for old links.
export function load() {
	redirect(308, '/');
}
