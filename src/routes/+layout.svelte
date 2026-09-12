<script lang="ts">
	import '../app.css';
	import Header from '$lib/components/Header.svelte';
	import Footer from '$lib/components/Footer.svelte';
	import { Toaster, toast } from 'svelte-5-french-toast';
	import { page } from '$app/stores';
	import { devModeState } from '$lib/stores/devMode.svelte';

	let { children } = $props();

	let isSandboxChild = $state(false);
	
	$effect(() => {
		isSandboxChild = window.location.search.includes('sandbox=true');
	});

	const showSandboxLayout = $derived(!isSandboxChild && devModeState.active && devModeState.previewMode !== 'desktop');

	$effect(() => {
		const handleClick = () => toast.dismiss();
		window.addEventListener('click', handleClick);
		return () => window.removeEventListener('click', handleClick);
	});

	// SEO Meta helpers
	const siteName = 'Blueprint';
	const baseUrl = 'https://ftcblueprint.com';
	const canonicalUrl = $derived(`${baseUrl}${$page.url.pathname}`);
	
	// Default meta values - these can be overridden in sub-pages
	const defaultDescription = 'Blueprint - the complete guide for FTC teams. Coding, hardware, and strategy made simple. Learn ftcblueprint, blueprint ftc, and more.';
	const defaultKeywords = 'ftcblueprint, ftc blueprint, blueprint ftc, blueprint, blueprintftc, FIRST Tech Challenge, robotics guide';
	const defaultImage = `${baseUrl}/favicon.png`; // Fallback image
</script>

<svelte:head>
	<!-- Primary Meta Tags -->
	<link rel="canonical" href={canonicalUrl} />
	<meta name="description" content={defaultDescription} />
	<meta name="keywords" content={defaultKeywords} />

	<!-- Open Graph / Facebook -->
	<meta property="og:type" content="website" />
	<meta property="og:url" content={canonicalUrl} />
	<meta property="og:title" content={siteName} />
	<meta property="og:description" content={defaultDescription} />
	<meta property="og:image" content={defaultImage} />

	<!-- Twitter -->
	<meta property="twitter:card" content="summary_large_image" />
	<meta property="twitter:url" content={canonicalUrl} />
	<meta property="twitter:title" content={siteName} />
	<meta property="twitter:description" content={defaultDescription} />
	<meta property="twitter:image" content={defaultImage} />
</svelte:head>

<Toaster />

{#if showSandboxLayout}
	<div class="sandbox-overlay">
		<Header />
		<div class="sandbox-workspace">
			<div class="device-frame" class:tablet={devModeState.previewMode === 'tablet'} class:mobile={devModeState.previewMode === 'mobile'}>
				<iframe src="{$page.url.pathname}?sandbox=true" title="Responsive Device Sandbox"></iframe>
			</div>
		</div>
	</div>
{:else}
	<div class="site-wrapper" class:mock-body={isSandboxChild}>
		<Header />
		<main class="main-content">
			{@render children()}
		</main>
		<Footer />
	</div>
{/if}

<style>
	.site-wrapper {
		display: flex;
		flex-direction: column;
		min-height: 100vh;
	}

	.site-wrapper.mock-body {
		background: var(--bg);
	}

	.main-content {
		flex: 1;
	}

	.sandbox-overlay {
		display: flex;
		flex-direction: column;
		height: 100vh;
		width: 100vw;
		overflow: hidden;
		background: var(--bg);
	}
	
	.sandbox-workspace {
		flex: 1;
		display: flex;
		align-items: center;
		justify-content: center;
		background: var(--bg-hover);
		padding: 2rem;
		overflow: hidden;
	}

	.device-frame {
		background: var(--bg);
		border: 8px solid var(--border-subtle);
		border-radius: var(--radius-xl);
		box-shadow: 0 30px 60px rgba(0,0,0,0.3);
		overflow: hidden;
		transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
		display: flex;
		flex-direction: column;
	}

	.device-frame.tablet {
		width: 768px;
		height: 1024px;
		max-height: 90vh;
	}

	.device-frame.mobile {
		width: 390px;
		height: 844px;
		max-height: 90vh;
		border-radius: 0;
	}

	.device-frame iframe {
		flex: 1;
		width: 100%;
		border: none;
		background: var(--bg);
	}
</style>
