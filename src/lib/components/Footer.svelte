<script lang="ts">
	const year = new Date().getFullYear();
</script>

<footer class="footer">
	<div class="inner">
		<div class="brand">
			<a href="/" class="logo">
				<span class="logo-mark">⬡</span>
				<span>Blueprint</span>
			</a>
			<p class="tagline">FTC software documentation</p>
		</div>

		<nav class="footer-nav" aria-label="Footer navigation">
			<a href="/">Software</a>
			<a href="/simulators/pid">Simulators</a>
			<a href="/complete-rookie-guide">Rookie Guide</a>
			<a href="/review">Get a Free Review</a>
			<a href="/suggest">Suggest</a>
		</nav>

		<p class="copy">&copy; {year} Blueprint</p>
	</div>
</footer>

<style>
	.footer {
		margin-top: auto;
		border-top: 1px solid var(--border);
		background: var(--bg-secondary);
		padding: 2rem 0 1.25rem;
	}

	.inner {
		max-width: 1560px;
		margin: 0 auto;
		padding: 0 1.5rem;
		display: grid;
		grid-template-columns: 1fr auto;
		gap: 1rem 2rem;
		align-items: start;
	}

	.brand {
		display: flex;
		flex-direction: column;
		gap: 0.3rem;
	}

	.logo {
		display: flex;
		align-items: center;
		gap: 0.4rem;
		font-weight: 700;
		font-size: 1rem;
		color: var(--text-primary);
		text-decoration: none;
	}

	.logo-mark {
		font-size: 1.1rem;
	}

	.tagline {
		font-size: 0.8rem;
		color: var(--text-muted);
	}

	.footer-nav {
		display: flex;
		flex-wrap: wrap;
		gap: 0.4rem 1.25rem;
		justify-content: flex-end;
	}

	.footer-nav a {
		font-size: 0.85rem;
		color: var(--text-secondary);
		text-decoration: none;
	}

	.footer-nav a:hover {
		color: var(--text-primary);
	}

	.copy {
		grid-column: 1 / -1;
		font-size: 0.75rem;
		color: var(--text-muted);
		border-top: 1px solid var(--border);
		padding-top: 1rem;
		margin-top: 0.5rem;
	}

	@media (max-width: 600px) {
		.inner {
			grid-template-columns: 1fr;
		}

		.footer-nav {
			justify-content: flex-start;
		}
	}
</style>
