<script lang="ts">
	import CodeReview from '$lib/components/CodeReview.svelte';
	import CADReview from '$lib/components/CADReview.svelte';
	import PortfolioReview from '$lib/components/PortfolioReview.svelte';
	import { onMount } from 'svelte';

	let activeTab = $state<'code' | 'cad' | 'portfolio'>('portfolio');

	onMount(() => {
		const params = new URLSearchParams(window.location.search);
		const tab = params.get('tab');
		if (tab === 'cad' || tab === 'code') activeTab = tab;
	});

	const tabs = [
		{ id: 'portfolio', label: 'Portfolio Review' },
		{ id: 'code',      label: 'Code Review'      },
		{ id: 'cad',       label: 'CAD Review'       },
	] as const;
</script>

<svelte:head>
	<title>Review | Blueprint</title>
	<meta name="description" content="Free code, CAD, and engineering portfolio reviews for FTC teams." />
</svelte:head>

<!-- Hero -->
<section class="review-hero">
	<div class="container">
		<div class="hero-inner animate-fade-up">
			<div class="hero-text">
				<h1>Get a Free Review</h1>
				<p class="sub">
					Submit your code, CAD, or engineering portfolio and we will send back written feedback.
					Free for all FTC teams.
				</p>
			</div>
			<div class="hero-badges">
				{#each tabs as tab}
					<button class="hero-badge" onclick={() => (activeTab = tab.id)}>
						<span class="badge-label">{tab.label}</span>
					</button>
				{/each}
			</div>
		</div>
	</div>
</section>

<!-- Tab bar -->
<div class="tab-bar-wrap">
	<div class="container">
		<nav class="tab-bar" aria-label="Review type">
			{#each tabs as tab}
				<button
					class="tab-btn"
					class:active={activeTab === tab.id}
					onclick={() => (activeTab = tab.id)}
					id="review-tab-{tab.id}"
				>
					{tab.label}
				</button>
			{/each}
		</nav>
	</div>
</div>

<!-- Panel -->
<section class="review-panel">
	<div class="container">
		{#if activeTab === 'code'}
			<div class="panel-inner animate-fade-up">
				<CodeReview />
			</div>
		{:else if activeTab === 'cad'}
			<div class="panel-inner animate-fade-up">
				<CADReview />
			</div>
		{:else}
			<div class="panel-inner animate-fade-up">
				<PortfolioReview />
			</div>
		{/if}
	</div>
</section>

<style>
	/* ── Hero ── */
	.review-hero {
		padding: 4rem 0 2.5rem;
		background: var(--gradient-hero);
		border-bottom: 1px solid var(--border-subtle);
	}

	.hero-inner {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: space-between;
		gap: 2.5rem;
	}

	.hero-text {
		display: flex;
		flex-direction: column;
		gap: 1rem;
		max-width: 560px;
	}

	h1 {
		font-size: clamp(2.2rem, 5vw, 3.5rem);
		line-height: 1.1;
		margin: 0;
	}

	.sub {
		font-size: 1.05rem;
		color: var(--text-secondary);
		line-height: 1.65;
		margin: 0;
	}

	.hero-badges {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.hero-badge {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		padding: 0.8rem 1.25rem;
		background: var(--bg-card);
		border: 1px solid var(--border);
		border-radius: var(--radius-md);
		font-size: 0.9rem;
		font-weight: 400;
		color: var(--text-primary);
		min-width: 220px;
		cursor: pointer;
		transition: all var(--transition-fast);
		text-align: left;
		font-family: var(--font-body);
	}

	.hero-badge:hover {
		transform: none;
		border-color: var(--accent-cyan);
		background: var(--bg-secondary);
	}

	/* ── Tab bar ── */
	.tab-bar-wrap {
		position: sticky;
		top: var(--header-height);
		z-index: 20;
		background: var(--bg);
		border-bottom: 1px solid var(--border-subtle);
		backdrop-filter: blur(10px);
		-webkit-backdrop-filter: blur(10px);
	}

	.tab-bar {
		display: flex;
		gap: 0;
		overflow-x: auto;
		scrollbar-width: none;
	}

	.tab-bar::-webkit-scrollbar { display: none; }

	.tab-btn {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		padding: 1rem 1.5rem;
		background: transparent;
		border: none;
		border-bottom: 2px solid transparent;
		font-family: var(--font-sans);
		font-size: 0.9rem;
		font-weight: 400;
		color: var(--text-secondary);
		cursor: pointer;
		white-space: nowrap;
		transition:
			color var(--transition-fast),
			border-color var(--transition-fast);
		position: relative;
		top: 1px; /* align with border-bottom of wrap */
	}

	.tab-btn:hover {
		color: var(--text-primary);
	}

	.tab-btn.active {
		color: var(--text-primary);
		border-bottom-color: var(--accent-cyan);
		font-weight: 400;
	}





	/* ── Panel ── */
	.review-panel {
		padding: 3rem 0 6rem;
		min-height: 60vh;
	}

	.panel-inner {
		max-width: 900px;
	}

	/* ── Responsive ── */
	@media (max-width: 700px) {
		.hero-badges { display: none; }
		.tab-btn { padding: 0.85rem 1rem; font-size: 0.8rem; }
	}
</style>
