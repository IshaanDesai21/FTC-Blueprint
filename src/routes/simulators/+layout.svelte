<script lang="ts">
	import { onMount } from 'svelte';
	import { fade } from 'svelte/transition';

	let { children } = $props();

	let showMobileWarning = $state(false);

	onMount(() => {
		if (typeof window !== 'undefined') {
			if (window.innerWidth < 850) {
				showMobileWarning = true;
			}
		}
	});

	function closeWarning() {
		showMobileWarning = false;
	}
</script>

{#if showMobileWarning}
	<div class="mobile-overlay" transition:fade={{ duration: 200 }}>
		<div class="mobile-warning-card">
			<svg
				width="48"
				height="48"
				viewBox="0 0 24 24"
				fill="none"
				stroke="currentColor"
				stroke-width="2"
				stroke-linecap="round"
				stroke-linejoin="round"
				class="warning-icon"
			>
				<rect width="18" height="18" x="3" y="3" rx="2" ry="2" />
				<line x1="9" x2="15" y1="9" y2="9" />
				<line x1="9" x2="15" y1="15" y2="15" />
			</svg>
			<h2>Desktop Recommended</h2>
			<p>This simulator needs a keyboard and a wide screen. Open it on a computer.</p>

			<div class="buttons">
				<a href="/" class="btn-primary">Back to docs</a>
				<button class="btn-secondary" onclick={closeWarning}>Continue anyway</button>
			</div>
		</div>
	</div>
{/if}

<div class="simulator-wrapper" class:blurred={showMobileWarning}>
	{@render children()}
</div>

<style>
	.mobile-overlay {
		position: fixed;
		inset: 0;
		background: rgba(10, 10, 12, 0.85);
		backdrop-filter: blur(8px);
		-webkit-backdrop-filter: blur(8px);
		z-index: 9999;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 1.5rem;
	}

	:global(html.light) .mobile-overlay {
		background: rgba(240, 246, 248, 0.88);
	}

	.mobile-warning-card {
		background: var(--bg-card);
		border: 1px solid var(--border);
		border-radius: var(--radius-lg);
		padding: 2.5rem;
		max-width: 480px;
		text-align: center;
		box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
	}

	.warning-icon {
		color: var(--accent-cyan);
		margin-bottom: 1.5rem;
	}

	h2 {
		font-family: var(--font-heading);
		font-size: 1.5rem;
		margin-bottom: 1rem;
		color: var(--text-primary);
	}

	p {
		color: var(--text-secondary);
		line-height: 1.6;
		margin-bottom: 1.5rem;
		font-size: 0.95rem;
	}

	.buttons {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
		margin-top: 2rem;
	}

	.btn-primary {
		padding: 0.75rem 1.5rem;
		background: var(--text-primary);
		color: var(--bg);
		border-radius: var(--radius-md);
		text-decoration: none;
		font-weight: 500;
		transition: background var(--transition-fast);
	}

	.btn-primary:hover {
		background: var(--text-secondary);
	}

	.btn-secondary {
		padding: 0.75rem 1.5rem;
		background: transparent;
		color: var(--text-secondary);
		border: 1px solid var(--border);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-size: 0.9rem;
		transition: all var(--transition-fast);
	}

	.btn-secondary:hover {
		background: rgba(116, 215, 237, 0.1);
		color: var(--text-primary);
		border-color: var(--accent-cyan);
	}

	.blurred {
		filter: blur(8px);
		pointer-events: none;
		user-select: none;
	}
</style>
