<script lang="ts">
	import { page } from '$app/stores';
	import ThemeToggle from './ThemeToggle.svelte';
	import { devModeState, setDevMode, initDevMode, setPreviewMode } from '$lib/stores/devMode.svelte';
	import { goto } from '$app/navigation';
	import toast from 'svelte-5-french-toast';
	import { onMount } from 'svelte';

	let isSandboxChild = $state(false);

	onMount(() => {
		initDevMode();
		isSandboxChild = window.location.search.includes('sandbox=true');

		window.addEventListener('clearHeaderSearch', () => {
			displayQuery = '';
			actualQuery = '';
		});
		if (typeof navigator !== 'undefined') {
			isMac = /Mac|iPhone|iPad|iPod/.test(navigator.platform) || /Mac|iPhone|iPad|iPod/.test(navigator.userAgent);
		}
	});

	let displayQuery = $state('');
	let actualQuery = $state('');

	function handleHeaderInput(e: Event) {
		const target = e.target as HTMLInputElement;
		const val = target.value;

		if ($page.url.pathname === '/search') {
			displayQuery = '';
			actualQuery = '';
			document.getElementById('main-search-input')?.focus();
			window.dispatchEvent(new CustomEvent('headerToMainSearchSync', { detail: val }));
			return;
		}

		if (val.startsWith('/dev') || val.startsWith('/reg')) {
			const prefix = val.substring(0, 4);
			const typedSuffix = val.substring(4);
			const realSuffix = actualQuery.length > 4 ? actualQuery.substring(4) : '';

			if (typedSuffix.length > realSuffix.length) {
				const addedStr = typedSuffix.slice(-(typedSuffix.length - realSuffix.length));
				actualQuery = prefix + realSuffix + addedStr;
			} else if (typedSuffix.length < realSuffix.length) {
				actualQuery = prefix + realSuffix.slice(0, typedSuffix.length);
			} else {
				actualQuery = val;
			}
			displayQuery = prefix + '*'.repeat(Math.max(0, actualQuery.length - 4));
			target.value = displayQuery;
		} else {
			actualQuery = val;
			displayQuery = val;
		}
	}

	function handleHeaderFocus() {
		if ($page.url.pathname === '/search') {
			document.getElementById('main-search-input')?.focus();
		}
	}

	let headerSearchInput = $state<HTMLInputElement | null>(null);
	let isMac = $state(true);

	function handleWindowKeydown(e: KeyboardEvent) {
		if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
			e.preventDefault();
			if ($page.url.pathname === '/search') {
				document.getElementById('main-search-input')?.focus();
			} else {
				headerSearchInput?.focus();
			}
		}
	}

	type NavLink = {
		label: string;
		href?: string;
		match?: string;
		devOnly?: boolean;
		children?: NavLink[];
	};

	const navLinks: NavLink[] = [
		{ href: '/software', label: 'Software', match: '/software' },
		{
			label: 'Simulators',
			match: '/simulators',
			children: [
				{ href: '/simulators/pid', label: 'PID Simulator' },
				{ href: '/simulators/mecanum', label: 'Mecanum Simulator' },
				{ href: '/simulators/model-converter', label: 'Model Converter', devOnly: true }
			]
		},
		{ href: '/complete-rookie-guide', label: 'Rookie Guide', match: '/complete-rookie-guide' },
		{ href: '/review', label: 'Get a Free Review', match: '/review' },
		{ href: '/suggest', label: 'Suggest', match: '/suggest' },
		{ href: '/editor', label: 'Editor', match: '/editor', devOnly: true },
		{ href: '/software/markdown-reference', label: 'Markdown Reference', match: '/software/markdown-reference', devOnly: true }
	];

	const visibleNavLinks = $derived(
		navLinks
			.filter((item) => !item.devOnly || devModeState.active)
			.map((item) => {
				if (item.children) {
					return {
						...item,
						children: item.children.filter((child) => !child.devOnly || devModeState.active)
					};
				}
				return item;
			})
	);

	let menuOpen = $state(false);
	let dropdownOpen = $state(false);

	function closeMenu() {
		menuOpen = false;
		dropdownOpen = false;
	}

	function handleSearchSubmit(e: Event) {
		e.preventDefault();
		if (actualQuery.trim()) {
			const q = actualQuery.trim();
			if (q === '/dev3432') {
				setDevMode(true);
				toast.success('Developer Mode Enabled');
				displayQuery = '';
				actualQuery = '';
				return;
			}
			if (q === '/reg3432') {
				setDevMode(false);
				toast.success('Regular Mode Enabled');
				displayQuery = '';
				actualQuery = '';
				return;
			}
			goto(`/search?q=${encodeURIComponent(q)}`);
			displayQuery = '';
			actualQuery = '';
		}
	}

	const isActive = (match?: string) => {
		if (!match) return false;
		const p = $page.url.pathname;
		return p === match || p.startsWith(`${match}/`);
	};
</script>

<svelte:window onkeydown={handleWindowKeydown} />

<header class="header">
	<div class="inner">
		<a href="/" class="logo" onclick={closeMenu}>
			<span class="logo-mark">⬡</span>
			<span class="logo-text">Blueprint</span>
		</a>

		<nav class="nav" class:open={menuOpen} aria-label="Main navigation">
			{#each visibleNavLinks as item}
				{#if item.children}
					<!-- svelte-ignore a11y_no_static_element_interactions -->
					<div
						class="nav-dropdown"
						class:open={dropdownOpen}
						onmouseenter={() => { if (typeof window !== 'undefined' && window.innerWidth > 1024) dropdownOpen = true; }}
						onmouseleave={() => { if (typeof window !== 'undefined' && window.innerWidth > 1024) dropdownOpen = false; }}
					>
						<button
							type="button"
							class="nav-link dropdown-toggle"
							class:active={isActive(item.match)}
							aria-expanded={dropdownOpen}
							aria-haspopup="true"
							onclick={() => (dropdownOpen = !dropdownOpen)}
						>
							{item.label}
							<span class="chevron">▾</span>
						</button>

						<div class="dropdown-menu">
							{#each item.children as child}
								<a
									href={child.href}
									class="dropdown-link"
									class:active={$page.url.pathname === child.href}
									aria-current={$page.url.pathname === child.href ? 'page' : undefined}
									onclick={closeMenu}
								>
									{child.label}
								</a>
							{/each}
						</div>
					</div>
				{:else}
					<a
						href={item.href}
						class="nav-link"
						class:active={isActive(item.match)}
						aria-current={isActive(item.match) ? 'page' : undefined}
						onclick={closeMenu}
					>
						{item.label}
					</a>
				{/if}
			{/each}
		</nav>

		<div class="actions">
			<form class="header-search-wrap" onsubmit={handleSearchSubmit}>
				<svg
					class="search-icon"
					width="15"
					height="15"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2.5"
					stroke-linecap="round"
					stroke-linejoin="round"
				>
					<circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
				</svg>
				<input
					bind:this={headerSearchInput}
					type="search"
					placeholder="Search"
					bind:value={displayQuery}
					oninput={handleHeaderInput}
					onfocus={handleHeaderFocus}
					class="header-search-input"
				/>
				{#if devModeState.active}
					<span class="dev-badge">DEV</span>
				{:else}
					<span class="search-cmd">{isMac ? '⌘K' : 'Ctrl K'}</span>
				{/if}
			</form>

			<a href="/search" class="action-btn mobile-search-btn" aria-label="Search" title="Search">
				<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
					<circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
				</svg>
			</a>

			{#if devModeState.active && !isSandboxChild}
				<div class="viewport-toggle">
					<button class="view-btn" class:active={devModeState.previewMode === 'desktop'} onclick={() => setPreviewMode('desktop')} title="Desktop View">
						<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14"></rect><line x1="8" y1="21" x2="16" y2="21"></line><line x1="12" y1="17" x2="12" y2="21"></line></svg>
					</button>
					<button class="view-btn" class:active={devModeState.previewMode === 'tablet'} onclick={() => setPreviewMode('tablet')} title="Tablet View">
						<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="2" width="16" height="20"></rect><line x1="12" y1="18" x2="12.01" y2="18"></line></svg>
					</button>
					<button class="view-btn" class:active={devModeState.previewMode === 'mobile'} onclick={() => setPreviewMode('mobile')} title="Mobile View">
						<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="6" y="2" width="12" height="20"></rect><line x1="12" y1="18" x2="12.01" y2="18"></line></svg>
					</button>
				</div>
			{/if}

			<ThemeToggle />

			<button
				class="menu-btn"
				aria-label="Toggle menu"
				aria-expanded={menuOpen}
				onclick={() => (menuOpen = !menuOpen)}
			>
				<span class="bar" class:open={menuOpen}></span>
				<span class="bar" class:open={menuOpen}></span>
				<span class="bar" class:open={menuOpen}></span>
			</button>
		</div>
	</div>
</header>

{#if menuOpen}
	<div
		class="backdrop"
		role="button"
		tabindex="-1"
		aria-label="Close menu"
		onclick={closeMenu}
		onkeydown={(e) => e.key === 'Enter' && closeMenu()}
	></div>
{/if}

<style>
	.header {
		position: sticky;
		top: 0;
		z-index: 100;
		height: var(--header-height);
		background: var(--bg-header);
		backdrop-filter: blur(8px);
		-webkit-backdrop-filter: blur(8px);
		border-bottom: 1px solid var(--border);
	}

	.inner {
		display: flex;
		align-items: center;
		gap: 1.5rem;
		height: 100%;
		max-width: 1560px;
		margin: 0 auto;
		padding: 0 1.5rem;
	}

	.actions {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		margin-left: auto;
		flex-shrink: 0;
	}

	.logo {
		display: flex;
		align-items: center;
		gap: 0.45rem;
		text-decoration: none;
		color: var(--text-primary);
		font-weight: 700;
		font-size: 1.05rem;
		letter-spacing: -0.01em;
		flex-shrink: 0;
	}

	.logo:hover {
		color: var(--text-primary);
	}

	.logo-mark {
		font-size: 1.25rem;
		line-height: 1;
	}

	.nav {
		display: flex;
		align-items: center;
		gap: 0.15rem;
		height: 100%;
	}

	.nav-link {
		position: relative;
		display: inline-flex;
		align-items: center;
		height: var(--header-height);
		padding: 0 0.75rem;
		font-size: 0.875rem;
		font-weight: 500;
		color: var(--text-secondary);
		text-decoration: none;
		border-bottom: 2px solid transparent;
		margin-bottom: -1px;
		white-space: nowrap;
		transition: color var(--transition-fast);
	}

	.nav-link:hover {
		color: var(--text-primary);
	}

	.nav-link.active {
		color: var(--text-primary);
		border-bottom-color: var(--text-primary);
	}

	.nav-dropdown {
		position: relative;
		height: 100%;
	}

	.dropdown-toggle {
		gap: 0.3rem;
		background: transparent;
		border-top: none;
		border-left: none;
		border-right: none;
		cursor: pointer;
	}

	.chevron {
		font-size: 0.75rem;
		transition: transform var(--transition-base);
	}

	.nav-dropdown.open .chevron {
		transform: rotate(180deg);
	}

	.dropdown-menu {
		position: absolute;
		top: 100%;
		left: 0;
		min-width: 200px;
		padding: 0.35rem;
		border: 1px solid var(--border);
		background: var(--bg-card);
		box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
		opacity: 0;
		visibility: hidden;
		transition: opacity var(--transition-fast), visibility var(--transition-fast);
		z-index: 120;
	}

	.nav-dropdown.open .dropdown-menu,
	.nav-dropdown:hover .dropdown-menu,
	.nav-dropdown:focus-within .dropdown-menu {
		opacity: 1;
		visibility: visible;
	}

	.dropdown-link {
		display: block;
		padding: 0.5rem 0.7rem;
		font-size: 0.85rem;
		color: var(--text-secondary);
		text-decoration: none;
	}

	.dropdown-link:hover,
	.dropdown-link.active {
		color: var(--text-primary);
		background: var(--bg-secondary);
	}

	.header-search-wrap {
		position: relative;
		display: flex;
		align-items: center;
	}

	.viewport-toggle {
		display: flex;
		align-items: center;
		background: var(--bg-secondary);
		border: 1px solid var(--border);
		padding: 0.1rem;
		gap: 0.1rem;
	}

	.view-btn {
		background: transparent;
		border: none;
		color: var(--text-muted);
		width: 28px;
		height: 28px;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
	}

	.view-btn:hover {
		color: var(--text-secondary);
	}

	.view-btn.active {
		background: var(--bg-card);
		color: var(--text-primary);
	}

	.header-search-wrap .search-icon {
		position: absolute;
		left: 0.65rem;
		color: var(--text-muted);
		pointer-events: none;
	}

	.header-search-input {
		background: var(--bg-secondary);
		border: 1px solid var(--border);
		padding: 0.4rem 3rem 0.4rem 2rem;
		font-size: 0.85rem;
		color: var(--text-primary);
		width: 220px;
		outline: none;
		transition: border-color var(--transition-fast);
	}

	.header-search-input::placeholder {
		color: var(--text-muted);
	}

	.header-search-input:focus {
		border-color: var(--text-secondary);
		background: var(--bg-card);
	}

	.dev-badge {
		position: absolute;
		right: 0.5rem;
		top: 50%;
		transform: translateY(-50%);
		font-size: 0.6rem;
		font-family: var(--font-mono);
		font-weight: 700;
		letter-spacing: 0.08em;
		color: var(--bg);
		background: var(--text-primary);
		padding: 0.2em 0.5em;
		pointer-events: none;
	}

	.search-cmd {
		position: absolute;
		right: 0.5rem;
		top: 50%;
		transform: translateY(-50%);
		font-size: 0.65rem;
		color: var(--text-muted);
		background: var(--bg-card);
		border: 1px solid var(--border);
		padding: 0.1em 0.4em;
		pointer-events: none;
	}

	.action-btn {
		width: 36px;
		height: 36px;
		display: flex;
		align-items: center;
		justify-content: center;
		background: var(--bg-card);
		border: 1px solid var(--border);
		color: var(--text-secondary);
		cursor: pointer;
	}

	.mobile-search-btn {
		display: none !important;
	}

	.action-btn:hover {
		border-color: var(--text-primary);
		color: var(--text-primary);
	}

	.menu-btn {
		display: none;
		flex-direction: column;
		justify-content: center;
		align-items: center;
		gap: 5px;
		width: 36px;
		height: 36px;
		background: var(--bg-card);
		border: 1px solid var(--border);
		cursor: pointer;
		padding: 0;
	}

	.bar {
		display: block;
		width: 18px;
		height: 2px;
		background: var(--text-primary);
		transition:
			transform var(--transition-base),
			opacity var(--transition-base);
	}

	.bar.open:nth-child(1) {
		transform: translateY(7px) rotate(45deg);
	}
	.bar.open:nth-child(2) {
		opacity: 0;
	}
	.bar.open:nth-child(3) {
		transform: translateY(-7px) rotate(-45deg);
	}

	.backdrop {
		position: fixed;
		inset: 0;
		z-index: 99;
		background: rgba(0, 0, 0, 0.4);
	}

	@media (max-width: 1200px) {
		.inner {
			gap: 1rem;
		}

		.nav-link {
			padding: 0 0.55rem;
		}
	}

	@media (max-width: 1024px) {
		.menu-btn {
			display: flex;
		}

		.nav {
			position: fixed;
			top: var(--header-height);
			left: 0;
			z-index: 100;
			height: auto;
			flex-direction: column;
			align-items: stretch;
			gap: 0;
			width: 240px;
			padding: 0.5rem 0;
			background: var(--bg-card);
			border-right: 1px solid var(--border);
			border-bottom: 1px solid var(--border);
			transform: translateX(-100%);
			transition: transform var(--transition-base);
		}

		.nav.open {
			transform: translateX(0);
		}

		.nav-link {
			width: 100%;
			height: auto;
			padding: 0.65rem 1rem;
			border-bottom: none;
			border-left: 2px solid transparent;
			margin-bottom: 0;
		}

		.nav-link.active {
			border-left-color: var(--text-primary);
			background: var(--bg-secondary);
		}

		.nav-dropdown {
			width: 100%;
			height: auto;
		}

		.dropdown-toggle {
			width: 100%;
			justify-content: space-between;
		}

		.dropdown-menu {
			position: static;
			min-width: 0;
			width: 100%;
			padding: 0 0 0.25rem 1rem;
			border: none;
			box-shadow: none;
			background: transparent;
			display: none;
		}

		.nav-dropdown.open .dropdown-menu {
			display: block;
			opacity: 1;
			visibility: visible;
		}

		.dropdown-link {
			font-size: 0.85rem;
			padding: 0.5rem 1rem;
		}
	}

	@media (max-width: 640px) {
		.header-search-wrap {
			display: none;
		}

		.mobile-search-btn {
			display: flex !important;
		}
	}
</style>
