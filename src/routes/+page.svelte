<script lang="ts">
	import type { Post } from '$lib/utils/posts';
	import SoftwareLeftSidebar from '$lib/components/SoftwareLeftSidebar.svelte';
	import DocIndex from '$lib/components/DocIndex.svelte';

	let { data }: { data: { posts: Post[] } } = $props();
</script>

<svelte:head>
	<title>Blueprint | FTC Software Documentation</title>
	<meta name="description" content="FTC software documentation: OpModes, control, autonomous, sensors, and vision." />
</svelte:head>

<div class="main-layout">
	<SoftwareLeftSidebar />
	<div class="content-feed">
		<section class="page-header">
			<div class="page-header-inner">
				<div class="header-text">
					<h1>Software</h1>
				</div>
			</div>
		</section>

		<section class="index-section">
			<DocIndex posts={data.posts} section="software" />
		</section>
	</div>
</div>

<style>
	.main-layout {
		display: flex;
		flex-direction: column;
		width: 100%;
	}

	.content-feed {
		flex: 1;
		min-width: 0;
		max-width: 900px;
		padding: 0 2.5rem;
	}

	@media (min-width: 1101px) {
		.main-layout {
			flex-direction: row;
			align-items: flex-start;
		}
	}

	.page-header {
		padding: 2.5rem 0 1.5rem;
		border-bottom: 1px solid var(--border);
	}

	.page-header-inner {
		display: flex;
		flex-wrap: wrap;
		justify-content: space-between;
		align-items: center;
		gap: 1rem 2rem;
	}

	.header-text {
		display: flex;
		flex-direction: column;
		gap: 0.25rem;
	}

	h1 {
		font-size: 1.85rem;
		margin: 0;
	}

	.index-section {
		padding: 2rem 0 5rem;
	}

	@media (max-width: 640px) {
		.content-feed {
			padding: 0 1.25rem;
		}
	}
</style>
