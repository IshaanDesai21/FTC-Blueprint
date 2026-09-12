export const prerender = false;

export async function load({ parent }) {
	const { allPosts } = await parent();
	return { posts: allPosts };
}
