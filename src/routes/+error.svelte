<!-- src/routes/+error.svelte -->
<script lang="ts">
	import { page } from '$app/state';
</script>

<div class="error-page">
	<div class="container">
		<div class="error-content animate-fade-up">
			<span class="status-code">{page.status}</span>

			<h1>{page.status === 404 ? 'Page not found' : 'Something went wrong'}</h1>

			<p>
				{page.error?.message || 'The page could not be loaded.'}
			</p>

			<div class="actions">
				<a href="/" class="btn-primary">Return Home</a>
				<a href="/" class="btn-secondary">Browse Software</a>
			</div>
		</div>
	</div>
</div>

<style>
	.error-page {
		min-height: calc(100vh - var(--header-height, 64px) * 2);
		display: flex;
		align-items: center;
		justify-content: center;
		position: relative;
		overflow: hidden;
		padding: 4rem 1rem;
	}

	.error-content {
		text-align: center;
		max-width: 500px;
		margin: 0 auto;
	}

	.status-code {
		display: block;
		font-family: var(--font-mono);
		font-size: 8rem;
		font-weight: 800;
		line-height: 1;
		color: var(--text-primary);
		opacity: 0.2;
		margin-bottom: -2rem;
	}

	h1 {
		font-size: clamp(2rem, 5vw, 3rem);
		margin-bottom: 1rem;
		position: relative;
	}

	p {
		font-size: 1.1rem;
		color: var(--text-secondary);
		margin-bottom: 2.5rem;
		line-height: 1.6;
	}

	.actions {
		display: flex;
		gap: 1rem;
		justify-content: center;
	}

	.btn-primary,
	.btn-secondary {
		padding: 0.8rem 1.5rem;
		border-radius: var(--radius-md);
		font-weight: 600;
		font-size: 0.9rem;
		transition: all var(--transition-fast);
	}

	.btn-primary {
		background: var(--text-primary);
		color: var(--bg);
	}

	.btn-primary:hover {
		transform: none;
		
	}

	.btn-secondary {
		border: 1px solid var(--border);
		color: var(--text-primary);
	}

	.btn-secondary:hover {
		background: rgba(116, 215, 237, 0.05);
		border-color: var(--text-primary);
	}
</style>
