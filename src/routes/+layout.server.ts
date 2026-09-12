import { getAllPosts } from '$lib/utils/posts';

export const prerender = true;

export async function load() {
	const allPosts = await getAllPosts();
	return { allPosts };
}
