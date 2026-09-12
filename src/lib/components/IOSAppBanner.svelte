<script lang="ts">
	// TODO: swap in the real App Store URL once Blueprint is published.
	const appStoreUrl = 'https://apps.apple.com/app/blueprint-ftc';
</script>

<a href={appStoreUrl} class="ios-card animate-fade-up" aria-label="Download Blueprint on the App Store">
	<div class="ios-card__top">
		<img src="/app-icon.png" alt="" class="ios-card__icon" width="64" height="64" loading="lazy" />
		<div class="ios-card__meta">
			<span class="ios-card__name">Blueprint</span>
			<span class="ios-card__tagline">Guides &amp; simulators, native on your iPhone.</span>
		</div>
	</div>

	<span class="ios-card__badge">
		<svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
			<path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.53 4.08zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
		</svg>
		<span class="ios-card__badge-text">
			<span class="ios-card__badge-eyebrow">Download on the</span>
			<span class="ios-card__badge-title">App Store</span>
		</span>
	</span>
</a>

<style>
	.ios-card {
		display: flex;
		flex-direction: column;
		gap: 1.1rem;
		padding: 1.25rem;
		background: var(--gradient-card);
		border: 1px solid var(--border);
		border-radius: var(--radius-lg);
		text-decoration: none;
		transition:
			border-color var(--transition-fast),
			transform var(--transition-fast),
			box-shadow var(--transition-base);
	}

	.ios-card:hover {
		border-color: var(--text-primary);
		transform: translateY(-2px);
		box-shadow:
			var(--glow-cyan),
			0 10px 28px rgba(0, 0, 0, 0.16);
	}

	.ios-card__top {
		display: flex;
		align-items: center;
		gap: 1rem;
	}

	.ios-card__icon {
		flex-shrink: 0;
		width: 64px;
		height: 64px;
		border-radius: 0;
		border: 1px solid var(--border-subtle);
		box-shadow: 0 3px 10px rgba(0, 0, 0, 0.2);
	}

	.ios-card__meta {
		display: flex;
		flex-direction: column;
		gap: 0.2rem;
		min-width: 0;
	}

	.ios-card__name {
		font-family: var(--font-sans);
		font-weight: 600;
		font-size: 1.1rem;
		letter-spacing: -0.01em;
		color: var(--text-primary);
	}

	.ios-card__tagline {
		font-size: 0.82rem;
		color: var(--text-muted);
		line-height: 1.35;
	}

	.ios-card__badge {
		display: inline-flex;
		align-self: flex-start;
		align-items: center;
		gap: 0.65rem;
		padding: 0.5rem 1.05rem;
		background: var(--text-primary);
		color: var(--bg);
		border-radius: var(--radius-md);
		/* Apple's system font stack, so this renders in true San Francisco on Apple devices,
		   matching the real "Download on the App Store" badge instead of the site's house font. */
		font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", system-ui, sans-serif;
	}

	.ios-card__badge-text {
		display: flex;
		flex-direction: column;
		line-height: 1.15;
	}

	.ios-card__badge-eyebrow {
		font-size: 0.62rem;
		font-weight: 400;
		letter-spacing: 0.01em;
	}

	.ios-card__badge-title {
		font-size: 1.3rem;
		font-weight: 600;
		letter-spacing: -0.01em;
	}

	@media (max-width: 480px) {
		.ios-card__tagline {
			display: none;
		}
	}
</style>
