<script lang="ts">
	import { page } from '$app/state';
	import { onMount } from 'svelte';

	let message = $state('');
	let pageFrom = $state('');

	onMount(() => {
		message = page.url.searchParams.get('msg') ?? '';
		pageFrom = page.url.searchParams.get('from') ?? '';
	});
</script>

<div class="error-page">
	<div class="error-orb" aria-hidden="true"></div>
	<div class="container">
		<div class="error-content animate-fade-up">
			<span class="status-code">{page.status}</span>
			<h1>Success!</h1>
			<p>{message}</p>
			<div class="actions">
				<a href="/" class="btn-primary">Return Home</a>
				<a href={'/' + pageFrom} class="btn-secondary">Return to Previous Page</a>
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
	.error-orb {
		position: absolute;
		width: 600px;
		height: 600px;
		background: radial-gradient(circle, rgba(116, 215, 237, 0.1) 0%, transparent 70%);
		filter: blur(60px);
		z-index: -1;
		animation: pulse-glow 8s ease-in-out infinite;
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
		background: var(--text-primary);
		-webkit-background-clip: text;
		background-clip: text;
		-webkit-text-fill-color: transparent;
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
		transform: translateY(-2px);
		box-shadow: var(--glow-cyan);
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
