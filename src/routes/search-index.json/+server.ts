import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { getAllPosts } from '$lib/utils/posts';

export const prerender = true;

export type SearchDoc = {
	slug: string;
	href: string;
	title: string;
	description: string;
	tags: string[];
	completed: boolean;
	text: string;
};

// Turns article markdown into plain searchable text. Code is kept so names like setPower can be found.
function toPlainText(markdown: string): string {
	return markdown
		.replace(/^---[\s\S]*?\n---\n/, ' ')
		.replace(/<script[\s\S]*?<\/script>/gi, ' ')
		.replace(/<style[\s\S]*?<\/style>/gi, ' ')
		.replace(/```[a-zA-Z]*\n?/g, ' ')
		.replace(/!\[[^\]]*\]\([^)]*\)/g, ' ')
		.replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
		.replace(/<[^>]+>/g, ' ')
		.replace(/^\s{0,3}#{1,6}\s+/gm, '')
		.replace(/^\s*>\s?/gm, '')
		.replace(/^\s*[-*+]\s+/gm, '')
		.replace(/^\s*\d+\.\s+/gm, '')
		.replace(/[*`|]/g, ' ')
		.replace(/\$\$?/g, ' ')
		.replace(/\s+/g, ' ')
		.trim();
}

export async function GET() {
	const posts = await getAllPosts();
	const docs: SearchDoc[] = [];

	for (const post of posts) {
		const tags = (post.meta.tags || []).map((t) => String(t).toLowerCase().trim());
		const isRookieGuide = post.slug === 'complete-rookie-guide';
		if (!isRookieGuide && !tags.includes('software')) continue;

		const raw = readFileSync(join(process.cwd(), 'src/posts', `${post.slug}.md`), 'utf-8');

		docs.push({
			slug: post.slug,
			href: isRookieGuide ? '/complete-rookie-guide' : `/software/${post.slug}`,
			title: post.meta.title,
			description: post.meta.description || '',
			tags,
			completed: isRookieGuide || tags.includes('completed'),
			text: toPlainText(raw)
		});
	}

	return new Response(JSON.stringify(docs), {
		headers: { 'Content-Type': 'application/json' }
	});
}
