<script lang="ts">
	import type { PostMeta } from '$lib/utils/posts';
	import type { Component } from 'svelte';
	import { setupCopyButtons } from '$lib/utils/codeCopyButton';
	import SectionSidebar from '$lib/components/sectionSidebar.svelte';
	import SoftwareLeftSidebar from '$lib/components/SoftwareLeftSidebar.svelte';

	let { data }: { data: { content: Component; meta: PostMeta } } = $props();

	$effect(() => {
		setupCopyButtons();
	});
</script>

<svelte:head>
	<title>{data.meta.title} | Blueprint</title>
	<meta name="description" content={data.meta.description || data.meta.title} />
	<meta property="og:title" content={data.meta.title} />
	<meta property="og:description" content={data.meta.description || ''} />
</svelte:head>

<div class="doc-layout">
	<SoftwareLeftSidebar />

	<div class="doc-content">
	<article class="doc-main">
		<nav class="breadcrumbs" aria-label="Breadcrumb">
			<a href="/software">Software</a>
			{#if data.meta.panelCategory}
				<span class="sep">/</span>
				<span>{data.meta.panelCategory}</span>
			{/if}
		</nav>

		<header class="doc-header">
			<h1>{data.meta.title}</h1>
			{#if data.meta.description}
				<p class="doc-description">{data.meta.description}</p>
			{/if}
		</header>

		<div class="prose">
			<data.content />
		</div>

		<footer class="doc-footer">
			<a href="/software" class="back-link">← Back to Software</a>
		</footer>
	</article>

	<SectionSidebar contentSelector=".prose" />
	</div>
</div>

<style>
	.doc-layout {
		display: flex;
		align-items: flex-start;
	}

	.doc-content {
		flex: 1;
		min-width: 0;
		display: flex;
		align-items: flex-start;
		justify-content: center;
		gap: 3rem;
		padding: 0 2.5rem;
	}

	.doc-main {
		flex: 1;
		min-width: 0;
		max-width: 800px;
		padding: 2rem 0 4rem;
	}

	.breadcrumbs {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.8rem;
		color: var(--text-muted);
		margin-bottom: 1.25rem;
	}

	.breadcrumbs a {
		color: var(--text-muted);
		text-decoration: none;
	}

	.breadcrumbs a:hover {
		color: var(--text-primary);
	}

	.breadcrumbs .sep {
		opacity: 0.5;
	}

	.doc-header {
		margin-bottom: 2rem;
		padding-bottom: 1.25rem;
		border-bottom: 1px solid var(--border);
	}

	.doc-header h1 {
		font-size: clamp(1.75rem, 3vw, 2.25rem);
		margin-bottom: 0.5rem;
	}

	.doc-description {
		font-size: 1.05rem;
		color: var(--text-secondary);
		max-width: 640px;
	}

	.doc-footer {
		margin-top: 3rem;
		padding-top: 1.5rem;
		border-top: 1px solid var(--border);
	}

	.back-link {
		font-size: 0.875rem;
		color: var(--text-secondary);
		text-decoration: none;
	}

	.back-link:hover {
		color: var(--text-primary);
	}

	@media (max-width: 1100px) {
		.doc-content {
			padding: 0 1.5rem;
		}

		.doc-main {
			max-width: none;
			width: 100%;
		}
	}

	@media (max-width: 640px) {
		.doc-content {
			padding: 0 1.25rem;
		}
	}
</style>
