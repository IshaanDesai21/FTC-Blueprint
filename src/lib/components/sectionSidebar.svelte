<script lang="ts">
	import { browser } from '$app/environment';
	import { onMount } from 'svelte';

	let { contentSelector = '.prose' }: { contentSelector?: string } = $props();

	type HeadingEntry = {
		id: string;
		text: string;
		level: number; // 1 to 4
	};

	let headings: HeadingEntry[] = $state([]);
	let activeId: string = $state('');

	function slugify(text: string, index: number): string {
		const base = text
			.toLowerCase()
			.trim()
			.replace(/[^\w\s-]/g, '')
			.replace(/[\s_]+/g, '-')
			.replace(/-+/g, '-');
		return base || `heading-${index}`;
	}

	function buildHeadings() {
		if (!browser) return;

		const container = document.querySelector(contentSelector);
		if (!container) return;

		const els = container.querySelectorAll('h1, h2, h3, h4');
		const seen: Record<string, number> = {};

		const entries: HeadingEntry[] = [];

		els.forEach((el, i) => {
			const level = parseInt(el.tagName[1]);
			const text = el.textContent?.trim() ?? '';
			let slug = slugify(text, i);

			if (seen[slug] !== undefined) {
				seen[slug]++;
				slug = `${slug}-${seen[slug]}`;
			} else {
				seen[slug] = 0;
			}

			el.id = slug;

			entries.push({ id: slug, text, level });
		});

		headings = entries;
	}

	function scrollTo(id: string) {
		const el = document.getElementById(id);
		if (el) {
			el.scrollIntoView({ behavior: 'smooth', block: 'start' });
		}
	}

	function setupScrollSpy() {
		if (!browser) return;

		const observer = new IntersectionObserver(
			(entries) => {
				for (const entry of entries) {
					if (entry.isIntersecting) {
						activeId = entry.target.id;
					}
				}
			},
			{
				rootMargin: '-20% 0px -70% 0px',
				threshold: 0
			}
		);

		headings.forEach(({ id }) => {
			const el = document.getElementById(id);
			if (el) observer.observe(el);
		});

		return () => observer.disconnect();
	}

	function indentPx(level: number): string {
		return `${(level - 1) * 14}px`;
	}

	onMount(() => {
		buildHeadings();
		const cleanup = setupScrollSpy();
		return cleanup;
	});
</script>

{#if headings.length > 0}
	<nav class="section-sidebar" aria-label="Table of contents">
		<p class="sidebar-label">On this page</p>
		<ul class="sidebar-list">
			{#each headings as { id, text, level }}
				<li class="sidebar-item" style="padding-left: {indentPx(level)}">
					<a
						href="#{id}"
						class="sidebar-link level-{level}"
						class:active={activeId === id}
						onclick={(e) => {
							e.preventDefault();
							scrollTo(id);
							activeId = id;
						}}
					>
						{text}
					</a>
				</li>
			{/each}
		</ul>
	</nav>
{/if}

<style>
	.section-sidebar {
		position: sticky;
		top: calc(var(--header-height) + 2rem);
		width: 220px;
		flex-shrink: 0;
		max-height: calc(100vh - var(--header-height) - 4rem);
		overflow-y: auto;
		padding-right: 0.5rem;

		scrollbar-width: thin;
		scrollbar-color: var(--border) transparent;
	}

	.sidebar-label {
		font-size: 0.7rem;
		font-family: var(--font-mono);
		letter-spacing: 0.1em;
		text-transform: uppercase;
		color: var(--text-muted);
		margin-bottom: 0.75rem;
		padding-bottom: 0.5rem;
		border-bottom: 1px solid var(--border-subtle);
	}

	.sidebar-list {
		list-style: none;
		padding: 0;
		margin: 0;
		display: flex;
		flex-direction: column;
		gap: 2px;
	}

	.sidebar-item {
		transition: padding-left 200ms ease;
	}

	.sidebar-link {
		display: inline-block;
		position: relative;
		font-size: 0.78rem;
		font-family: var(--font-body);
		color: var(--text-muted);
		text-decoration: none;
		padding: 0.3rem 0;
		margin-left: 0.5rem;
		transition: color var(--transition-fast);
		line-height: 1.4;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.sidebar-link::after {
		content: '';
		position: absolute;
		bottom: 0;
		left: 0;
		width: 100%;
		height: 2px;
		background: var(--text-primary);
		transform: scaleX(0);
		transform-origin: left;
		transition: transform 0.3s ease;
	}

	.sidebar-link:hover {
		color: var(--text-primary);
	}

	.sidebar-link.active {
		color: var(--text-primary);
	}

	.sidebar-link:hover::after,
	.sidebar-link.active::after {
		transform: scaleX(1);
	}

	/* Level-specific weight differences */
	.sidebar-link.level-1 {
		font-weight: 600;
	}
	.sidebar-link.level-2 {
		font-weight: 500;
	}
	.sidebar-link.level-3 {
		font-weight: 400;
	}
	.sidebar-link.level-4 {
		font-weight: 400;
		font-style: italic;
	}

	/* Hide on narrow screens */
	@media (max-width: 1100px) {
		.section-sidebar {
			display: none;
		}
	}
</style>
