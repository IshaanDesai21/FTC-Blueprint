<script lang="ts">
	import { browser } from '$app/environment';
	import { afterNavigate } from '$app/navigation';
	import { onDestroy, tick } from 'svelte';

	let { contentSelector = '.prose' }: { contentSelector?: string } = $props();

	type HeadingEntry = {
		id: string;
		text: string;
		level: number;
	};

	let headings: HeadingEntry[] = $state([]);
	let activeId: string = $state('');

	// While a click-triggered smooth scroll is running, keep the clicked heading active
	// instead of stepping through every heading the page scrolls past.
	let lockedUntilScrollEnds = false;
	let scrollEndTimer: ReturnType<typeof setTimeout> | undefined;
	let frame = 0;

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
		const container = document.querySelector(contentSelector);
		if (!container) {
			headings = [];
			return;
		}

		// Only the article's own headings, not ones inside embedded widgets like the PID tuner.
		const els = [...container.querySelectorAll('h1, h2, h3, h4')].filter((el) => el.parentElement === container);
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

	function headerOffset(): number {
		const value = getComputedStyle(document.documentElement).getPropertyValue('--header-height');
		return (parseFloat(value) || 56) + 24;
	}

	function updateActive() {
		if (lockedUntilScrollEnds || headings.length === 0) return;

		const atBottom =
			window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2;
		if (atBottom) {
			activeId = headings[headings.length - 1].id;
			return;
		}

		const offset = headerOffset();
		let current = headings[0].id;
		for (const { id } of headings) {
			const el = document.getElementById(id);
			if (el && el.getBoundingClientRect().top - offset <= 1) {
				current = id;
			} else {
				break;
			}
		}
		activeId = current;
	}

	function onScroll() {
		if (lockedUntilScrollEnds) {
			clearTimeout(scrollEndTimer);
			scrollEndTimer = setTimeout(() => {
				lockedUntilScrollEnds = false;
			}, 150);
			return;
		}
		cancelAnimationFrame(frame);
		frame = requestAnimationFrame(updateActive);
	}

	function goTo(id: string) {
		const el = document.getElementById(id);
		if (!el) return;

		activeId = id;
		lockedUntilScrollEnds = true;
		clearTimeout(scrollEndTimer);
		scrollEndTimer = setTimeout(() => {
			lockedUntilScrollEnds = false;
		}, 1000);

		el.scrollIntoView({ behavior: 'smooth', block: 'start' });
		history.replaceState(history.state, '', `#${id}`);
	}

	function indentPx(level: number): string {
		return `${Math.max(0, level - 2) * 12}px`;
	}

	// SvelteKit reuses this component when moving between articles, so onMount alone
	// would leave the previous article's headings in place. Rebuild after every navigation.
	afterNavigate(async () => {
		headings = [];
		activeId = '';
		lockedUntilScrollEnds = false;
		await tick();
		buildHeadings();
		updateActive();
	});

	$effect(() => {
		if (!browser) return;
		window.addEventListener('scroll', onScroll, { passive: true });
		window.addEventListener('resize', onScroll, { passive: true });
		return () => {
			window.removeEventListener('scroll', onScroll);
			window.removeEventListener('resize', onScroll);
		};
	});

	onDestroy(() => {
		if (!browser) return;
		cancelAnimationFrame(frame);
		clearTimeout(scrollEndTimer);
	});
</script>

{#if headings.length > 0}
	<nav class="section-sidebar" aria-label="Table of contents">
		<p class="sidebar-label">On this page</p>
		<ul class="sidebar-list">
			{#each headings as { id, text, level } (id)}
				<li style="padding-left: {indentPx(level)}">
					<a
						href="#{id}"
						class="sidebar-link"
						class:sub={level > 2}
						class:active={activeId === id}
						aria-current={activeId === id ? 'location' : undefined}
						onclick={(e) => {
							e.preventDefault();
							goTo(id);
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

	.sidebar-link {
		display: inline-block;
		font-size: 0.8rem;
		font-weight: 500;
		color: var(--text-muted);
		text-decoration: none;
		padding: 0.3rem 0 0.2rem;
		margin-left: 0.5rem;
		border-bottom: 2px solid transparent;
		transition: none;
		line-height: 1.4;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		max-width: 100%;
	}

	.sidebar-link.sub {
		font-weight: 400;
	}

	.sidebar-link:hover {
		color: var(--text-primary);
	}

	.sidebar-link.active {
		color: var(--text-primary);
		border-bottom-color: var(--text-primary);
	}

	@media (max-width: 1100px) {
		.section-sidebar {
			display: none;
		}
	}
</style>
