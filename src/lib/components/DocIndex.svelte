<script lang="ts">
	import type { Post } from '$lib/utils/posts';

	let {
		posts,
		section
	}: { posts: Post[]; section: 'software' } = $props();

	// Only real, published pages
	const pages = $derived(posts.filter((p) => (p.meta.tags || []).includes('completed')));

	// Group by panelCategory, preserving a sensible order
	const groups = $derived.by(() => {
		const map = new Map<string, Post[]>();
		for (const p of pages) {
			const cat = p.meta.panelCategory || 'General';
			if (!map.has(cat)) map.set(cat, []);
			map.get(cat)!.push(p);
		}

		const priority = ['Basics', 'Getting Started', 'Sensors', 'Vision'];
		const cats = [...map.keys()].sort((a, b) => {
			const ia = priority.indexOf(a);
			const ib = priority.indexOf(b);
			if (ia !== -1 || ib !== -1) {
				return (ia === -1 ? 99 : ia) - (ib === -1 ? 99 : ib);
			}
			return a.localeCompare(b);
		});

		return cats.map((cat) => ({
			title: cat,
			items: map.get(cat)!.sort((a, b) => a.meta.title.localeCompare(b.meta.title))
		}));
	});
</script>

<div class="doc-index">
	{#each groups as group}
		<section class="group">
			<h2 class="group-title">{group.title}</h2>
			<ul>
				{#each group.items as page}
					<li>
						<a href="/{section}/{page.slug}">
							<span class="title">{page.meta.title}</span>
							{#if page.meta.description}
								<span class="desc">{page.meta.description}</span>
							{/if}
						</a>
					</li>
				{/each}
			</ul>
		</section>
	{/each}
</div>

<style>
	.doc-index {
		max-width: 760px;
	}

	.group {
		margin-bottom: 2.5rem;
	}

	.group-title {
		font-family: var(--font-sans);
		font-size: 0.75rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.05em;
		color: var(--text-muted);
		margin-bottom: 0.5rem;
		padding-bottom: 0.5rem;
		border-bottom: 1px solid var(--border-subtle);
	}

	ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	li a {
		display: block;
		padding: 0.7rem 0;
		border-bottom: 1px solid var(--border-subtle);
		text-decoration: none;
		color: inherit;
	}

	li:last-child a {
		border-bottom: none;
	}

	.title {
		display: block;
		font-size: 1rem;
		font-weight: 500;
		color: var(--text-primary);
	}

	li a:hover .title {
		color: var(--accent-cyan);
	}

	.desc {
		display: block;
		margin-top: 0.15rem;
		font-size: 0.88rem;
		line-height: 1.45;
		color: var(--text-secondary);
	}
</style>
