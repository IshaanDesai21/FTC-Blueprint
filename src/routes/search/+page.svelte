<script lang="ts">
	import { page } from '$app/stores';
	import BlogCard from '$lib/components/BlogCard.svelte';
	import type { Post } from '$lib/utils/posts';
	import { goto, replaceState } from '$app/navigation';

	import { devModeState, initDevMode } from '$lib/stores/devMode.svelte';
	import { onMount } from 'svelte';

	onMount(() => {
		initDevMode();
		window.addEventListener('clearPageSearch', () => {
			displayQuery = '';
			actualQuery = '';
			const url = new URL(window.location.href);
			url.searchParams.delete('q');
			replaceState(url, $page.state);
		});
	});

	let { data }: { data: { posts: Post[] } } = $props();

	let displayQuery = $state($page.url.searchParams.get('q') || '');
	let actualQuery = $state($page.url.searchParams.get('q') || '');

	function handleMainInput(e: Event) {
		const target = e.target as HTMLInputElement;
		const val = target.value;

		if (val.startsWith('/dev') || val.startsWith('/reg')) {
			const prefix = val.substring(0, 4);
			const typedSuffix = val.substring(4);
			const realSuffix = actualQuery.length > 4 ? actualQuery.substring(4) : '';

			if (typedSuffix.length > realSuffix.length) {
				const addedStr = typedSuffix.slice(-(typedSuffix.length - realSuffix.length));
				actualQuery = prefix + realSuffix + addedStr;
			} else if (typedSuffix.length < realSuffix.length) {
				actualQuery = prefix + realSuffix.slice(0, typedSuffix.length);
			} else {
				actualQuery = val;
			}
			displayQuery = prefix + '*'.repeat(Math.max(0, actualQuery.length - 4));
			target.value = displayQuery;
		} else {
			actualQuery = val;
			displayQuery = val;
		}

		// Also handle auto-unlocking on the search page!
		if (actualQuery === '/dev3432' || actualQuery === '/reg3432') {
			import('$lib/stores/devMode.svelte').then(({ setDevMode }) => {
				setDevMode(actualQuery === '/dev3432');
				import('svelte-5-french-toast').then(({ default: toast }) => {
					toast.success(actualQuery === '/dev3432' ? 'Developer Mode Enabled' : 'Regular Mode Enabled');
				});
				displayQuery = '';
				actualQuery = '';
			});
		}
	}

	$effect(() => {
		const url = new URL(window.location.href);
		if (actualQuery) {
			url.searchParams.set('q', actualQuery);
		} else {
			url.searchParams.delete('q');
		}
		if (url.search !== window.location.search) {
			replaceState(url, $page.state);
		}
	});

	const visiblePosts = $derived(
		data.posts.filter((p) => {
			if (devModeState.active) return true;
			const tags = (p.meta.tags || []).map((t) =>
				typeof t === 'string' ? t.toLowerCase().trim() : ''
			);
			return tags.includes('completed') || tags.includes('coming soon');
		})
	);

	const filteredPosts = $derived(
		visiblePosts.filter((p) => {
			const query = actualQuery.toLowerCase();
			if (!query) return true;
			return (
				(p.meta.title || '').toString().toLowerCase().includes(query) ||
				(p.meta.description || '').toString().toLowerCase().includes(query) ||
				(p.meta.tags || []).some((t) => typeof t === 'string' && t.toLowerCase().includes(query))
			);
		})
	);

	onMount(() => {
		window.addEventListener('headerToMainSearchSync', (e: Event) => {
			const ce = e as CustomEvent<string>;
			if (ce.detail) {
				actualQuery = ce.detail;
				displayQuery = ce.detail;
			}
			document.getElementById('main-search-input')?.focus();
		});
	});
</script>

<svelte:head>
	<title>Search | Blueprint</title>
</svelte:head>

<section class="search-page">
	<div class="container">
		<header class="search-header animate-fade-up">
			<h1>Search Blueprint</h1>
			<div class="search-input-wrap">
				<svg
					class="search-icon"
					width="20"
					height="20"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2.5"
					stroke-linecap="round"
					stroke-linejoin="round"
				>
					<circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
				</svg>
				<input
					id="main-search-input"
					type="text"
					placeholder="Search articles"
					bind:value={displayQuery}
					oninput={handleMainInput}
					class="search-input"
				/>
			</div>
			<p class="results-count">
				Found {filteredPosts.length} result{filteredPosts.length === 1 ? '' : 's'}
			</p>
		</header>

		<div class="results-grid stagger">
			{#each filteredPosts as post}
				<BlogCard {post} />
			{:else}
				<div class="empty-state animate-fade-up">
					<h3>No results found</h3>
					<p>No articles match that search.</p>
					<div style="display:flex; justify-content:center; gap:1rem;">
						<a href="/suggest" class="btn">Suggest a Guide</a>
						<a
							href="/"
							class="btn btn-ghost"
							style="background:transparent; border:1px solid var(--border); color:var(--text-secondary);"
							>Browse Guides</a
						>
					</div>
				</div>
			{/each}
		</div>
	</div>
</section>

<style>
	.search-page {
		padding: 6rem 0 12rem;
		min-height: 80vh;
	}

	.search-header {
		text-align: center;
		margin-bottom: 4rem;
		max-width: 600px;
		margin-left: auto;
		margin-right: auto;
	}

	h1 {
		margin-bottom: 2rem;
		font-size: clamp(2.5rem, 8vw, 4rem);
	}

	.search-input-wrap {
		position: relative;
		margin-bottom: 1rem;
	}

	.search-icon {
		position: absolute;
		left: 1.25rem;
		top: 50%;
		transform: translateY(-50%);
		color: var(--text-muted);
	}

	.search-input {
		width: 100%;
		padding: 1.25rem 1.5rem 1.25rem 3.5rem;
		background: var(--bg-card);
		border: 1px solid var(--border);
		border-radius: var(--radius-xl);
		color: var(--text-primary);
		font-size: 1.15rem;
		transition: all var(--transition-base);
		outline: none;
		box-shadow: none;
	}

	.search-input:focus {
		border-color: var(--text-primary);
		box-shadow: var(--glow-cyan);
		background: var(--bg);
	}

	.results-count {
		font-family: var(--font-mono);
		font-size: 0.85rem;
		color: var(--text-muted);
	}

	.results-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(min(320px, 100%), 1fr));
		gap: 2rem;
	}

	.empty-state {
		grid-column: 1 / -1;
		text-align: center;
		padding: 4rem 2rem;
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		border: 1px solid var(--border);
	}

	.empty-state h3 {
		margin-bottom: 1rem;
		color: var(--text-primary);
	}

	.empty-state p {
		margin-bottom: 2rem;
		color: var(--text-secondary);
	}

	.btn {
		display: inline-block;
		padding: 0.8rem 1.5rem;
		background: var(--text-primary);
		color: var(--bg);
		border-radius: var(--radius-md);
		font-family: var(--font-sans);
		font-weight: 600;
		transition: transform var(--transition-fast);
	}

	.btn:hover {
		transform: none;
	}
</style>
