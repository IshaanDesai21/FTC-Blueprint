<script lang="ts">
	import { formatDate, tagColor } from '$lib/utils/posts';
	import type { Post } from '$lib/utils/posts';

	let { post, basePath }: { post: Post; basePath?: string } = $props();

	const resolvedBasePath = $derived(basePath || '/software');
</script>

<a href="{resolvedBasePath}/{post.slug}" class="card animate-fade-up" aria-label="Read {post.meta.title}">
	<div class="card-inner">
		<div class="card-meta">
			<time class="date" datetime={post.meta.date}>{formatDate(post.meta.date)}</time>
			{#if post.meta.author}
				<span class="separator">·</span>
				<span class="author">{post.meta.author}</span>
			{/if}
		</div>

		<h2 class="card-title">{post.meta.title}</h2>

		{#if post.meta.description}
			<p class="card-desc">{post.meta.description}</p>
		{/if}

		{#if post.meta.tags && post.meta.tags.filter((t) => t.toLowerCase() !== 'completed').length > 0}
			<div class="tags">
				{#each post.meta.tags.filter((t) => t.toLowerCase() !== 'completed').slice(0, 3) as tag}
					<span class="tag {tagColor(tag)}">{tag}</span>
				{/each}
			</div>
		{/if}

		<div class="read-more">
			<span>Read post</span>
			<svg
				width="14"
				height="14"
				viewBox="0 0 24 24"
				fill="none"
				stroke="currentColor"
				stroke-width="2.5"
				stroke-linecap="round"
				stroke-linejoin="round"
				aria-hidden="true"
			>
				<path d="M5 12h14M12 5l7 7-7 7" />
			</svg>
		</div>
	</div>

	<!-- Decorative accent line -->
	<div class="accent-line" aria-hidden="true"></div>
</a>

<style>
	.card {
		position: relative;
		display: block;
		background: var(--gradient-card);
		border: 1px solid var(--border);
		border-radius: var(--radius-lg);
		text-decoration: none;
		overflow: hidden;
		transition:
			border-color var(--transition-base),
			transform var(--transition-base),
			box-shadow var(--transition-base);
	}

	.card:hover {
		border-color: var(--text-primary);
		transform: none;
		box-shadow:
			var(--glow-cyan),
			0 8px 32px rgba(0, 0, 0, 0.2);
	}

	.card:hover .accent-line {
		transform: scaleX(1);
	}

	.card:hover .read-more {
		color: var(--accent-green);
		gap: 0.6rem;
	}

	.card-inner {
		padding: 1.85rem 1.85rem;
		display: flex;
		flex-direction: column;
		gap: 0.9rem;
	}

	.card-meta {
		display: flex;
		align-items: center;
		gap: 0.4rem;
		font-size: 0.78rem;
		font-family: var(--font-mono);
		color: var(--text-muted);
	}

	.separator {
		opacity: 0.5;
	}
	.author {
		color: var(--accent-green);
	}

	.card-title {
		font-size: 1.2rem;
		font-weight: 600;
		color: var(--text-primary);
		line-height: 1.3;
		transition: color var(--transition-fast);
	}

	.card:hover .card-title {
		color: var(--accent-green);
	}

	.card-desc {
		font-size: 0.9rem;
		color: var(--text-body);
		line-height: 1.6;
		display: -webkit-box;
		-webkit-line-clamp: 2;
		line-clamp: 2;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}

	.tags {
		display: flex;
		flex-wrap: wrap;
		gap: 0.4rem;
	}

	.read-more {
		display: flex;
		align-items: center;
		gap: 0.4rem;
		margin-top: 0.25rem;
		font-size: 0.82rem;
		font-family: var(--font-sans);
		font-weight: 600;
		color: var(--text-muted);
		transition:
			color var(--transition-base),
			gap var(--transition-base);
	}

	.accent-line {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		height: 2px;
		background: var(--text-primary);
		transform: scaleX(0);
		transform-origin: left;
		transition: transform var(--transition-base);
	}
</style>
