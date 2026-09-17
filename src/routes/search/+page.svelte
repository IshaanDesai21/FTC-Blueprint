<script lang="ts">
	import { page } from '$app/stores';
	import { replaceState } from '$app/navigation';
	import { devModeState, initDevMode } from '$lib/stores/devMode.svelte';
	import { onMount } from 'svelte';
	import type { SearchDoc } from '../search-index.json/+server';

	let { data }: { data: { docs: SearchDoc[] } } = $props();

	let displayQuery = $state($page.url.searchParams.get('q') || '');
	let actualQuery = $state($page.url.searchParams.get('q') || '');

	onMount(() => {
		initDevMode();

		const clear = () => {
			displayQuery = '';
			actualQuery = '';
			const url = new URL(window.location.href);
			url.searchParams.delete('q');
			replaceState(url, $page.state);
		};
		const sync = (e: Event) => {
			const ce = e as CustomEvent<string>;
			if (ce.detail) {
				actualQuery = ce.detail;
				displayQuery = ce.detail;
			}
			document.getElementById('main-search-input')?.focus();
		};

		window.addEventListener('clearPageSearch', clear);
		window.addEventListener('headerToMainSearchSync', sync);
		return () => {
			window.removeEventListener('clearPageSearch', clear);
			window.removeEventListener('headerToMainSearchSync', sync);
		};
	});

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

	type Result = { doc: SearchDoc; score: number; snippet: string };

	function escapeHtml(s: string): string {
		return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
	}

	function escapeRegex(s: string): string {
		return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
	}

	function countOf(haystack: string, term: string): number {
		let n = 0;
		let i = haystack.indexOf(term);
		while (i !== -1) {
			n++;
			i = haystack.indexOf(term, i + term.length);
		}
		return n;
	}

	function highlight(text: string, terms: string[]): string {
		const escaped = escapeHtml(text);
		const pattern = terms
			.map((t) => escapeRegex(escapeHtml(t)))
			.sort((a, b) => b.length - a.length)
			.join('|');
		return pattern ? escaped.replace(new RegExp(`(${pattern})`, 'gi'), '<mark>$1</mark>') : escaped;
	}

	// A short window of body text around the first place a search term appears.
	function makeSnippet(text: string, terms: string[]): string {
		const lower = text.toLowerCase();
		let first = -1;
		for (const t of terms) {
			const i = lower.indexOf(t);
			if (i !== -1 && (first === -1 || i < first)) first = i;
		}
		if (first === -1) return '';

		let start = Math.max(0, first - 70);
		let end = Math.min(text.length, first + 150);
		if (start > 0) {
			const space = text.indexOf(' ', start);
			if (space !== -1 && space < first) start = space + 1;
		}
		if (end < text.length) {
			const space = text.lastIndexOf(' ', end);
			if (space > first) end = space;
		}

		return (start > 0 ? '… ' : '') + highlight(text.slice(start, end), terms) + (end < text.length ? ' …' : '');
	}

	const visibleDocs = $derived(data.docs.filter((d) => devModeState.active || d.completed));

	const terms = $derived(
		actualQuery.startsWith('/dev') || actualQuery.startsWith('/reg')
			? []
			: actualQuery.toLowerCase().split(/\s+/).filter(Boolean)
	);

	const results: Result[] = $derived.by(() => {
		if (terms.length === 0) return [];

		const out: Result[] = [];
		for (const doc of visibleDocs) {
			const title = doc.title.toLowerCase();
			const description = doc.description.toLowerCase();
			const tags = doc.tags.join(' ');
			const body = doc.text.toLowerCase();

			let score = 0;
			let allFound = true;
			for (const t of terms) {
				const inTitle = countOf(title, t);
				const inDesc = countOf(description, t);
				const inTags = countOf(tags, t);
				const inBody = countOf(body, t);
				if (inTitle + inDesc + inTags + inBody === 0) {
					allFound = false;
					break;
				}
				score += inTitle * 20 + inDesc * 8 + inTags * 5 + Math.min(inBody, 20);
			}
			if (!allFound) continue;

			out.push({ doc, score, snippet: makeSnippet(doc.text, terms) });
		}
		return out.sort((a, b) => b.score - a.score);
	});
</script>

<svelte:head>
	<title>Search | Blueprint</title>
</svelte:head>

<section class="search-page">
	<div class="container">
		<header class="search-header">
			<h1>Search</h1>
			<div class="search-input-wrap">
				<svg
					class="search-icon"
					width="18"
					height="18"
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
					placeholder="Search titles and article text"
					bind:value={displayQuery}
					oninput={handleMainInput}
					class="search-input"
					autocomplete="off"
					spellcheck="false"
				/>
			</div>
			{#if terms.length > 0}
				<p class="results-count">
					{results.length} result{results.length === 1 ? '' : 's'}
				</p>
			{/if}
		</header>

		{#if terms.length > 0}
			{#if results.length > 0}
				<ul class="results">
					{#each results as { doc, snippet } (doc.slug)}
						<li>
							<a href={doc.href} class="result">
								<span class="result-title">{@html highlight(doc.title, terms)}</span>
								{#if doc.description}
									<span class="result-desc">{doc.description}</span>
								{/if}
								{#if snippet}
									<span class="result-snippet">{@html snippet}</span>
								{/if}
							</a>
						</li>
					{/each}
				</ul>
			{:else}
				<div class="empty-state">
					<p>No articles contain that.</p>
					<a href="/suggest" class="empty-link">Suggest a guide</a>
				</div>
			{/if}
		{/if}
	</div>
</section>

<style>
	.search-page {
		padding: 3rem 0 8rem;
		min-height: 70vh;
	}

	.search-header {
		max-width: 760px;
		margin: 0 auto 2rem;
	}

	h1 {
		font-size: 1.85rem;
		margin-bottom: 1.25rem;
	}

	.search-input-wrap {
		position: relative;
		margin-bottom: 0.75rem;
	}

	.search-icon {
		position: absolute;
		left: 0.9rem;
		top: 50%;
		transform: translateY(-50%);
		color: var(--text-muted);
	}

	.search-input {
		width: 100%;
		padding: 0.8rem 1rem 0.8rem 2.6rem;
		background: var(--bg-card);
		border: 1px solid var(--border);
		color: var(--text-primary);
		font-size: 1rem;
		outline: none;
	}

	.search-input:focus {
		border-color: var(--text-secondary);
	}

	.results-count {
		font-family: var(--font-mono);
		font-size: 0.8rem;
		color: var(--text-muted);
	}

	.results {
		list-style: none;
		max-width: 760px;
		margin: 0 auto;
		border-top: 1px solid var(--border);
	}

	.result {
		display: block;
		padding: 1rem 0;
		border-bottom: 1px solid var(--border-subtle);
		text-decoration: none;
		color: inherit;
	}

	.result-title {
		display: block;
		font-size: 1.05rem;
		font-weight: 600;
		color: var(--text-primary);
	}

	.result:hover .result-title {
		color: var(--accent-cyan);
	}

	.result-desc {
		display: block;
		margin-top: 0.15rem;
		font-size: 0.88rem;
		color: var(--text-secondary);
	}

	.result-snippet {
		display: block;
		margin-top: 0.45rem;
		font-size: 0.85rem;
		line-height: 1.55;
		color: var(--text-body);
	}

	.result :global(mark) {
		background: color-mix(in srgb, var(--accent-yellow) 30%, transparent);
		color: var(--text-primary);
		padding: 0 0.1em;
	}

	.empty-state {
		max-width: 760px;
		margin: 0 auto;
		padding: 2rem 0;
		border-top: 1px solid var(--border);
		color: var(--text-secondary);
	}

	.empty-link {
		display: inline-block;
		margin-top: 0.5rem;
		color: var(--accent-cyan);
		text-decoration: underline;
		text-underline-offset: 3px;
	}
</style>
