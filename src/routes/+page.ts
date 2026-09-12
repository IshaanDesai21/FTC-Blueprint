export async function load({ parent }) {
	const { allPosts } = await parent();
	return { posts: allPosts.filter((p) => (p.meta.tags || []).includes('software')) };
}
