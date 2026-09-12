<script lang="ts">
	import { page } from '$app/stores';
	import { fade, slide } from 'svelte/transition';
	import { devModeState } from '$lib/stores/devMode.svelte';
	import type { Post } from '$lib/utils/posts';

	type Link = { href: string; label: string; devOnly: boolean };
	type Group = { title: string; links: Link[] };

	let currentPath = $derived($page.url.pathname);

	const categoryOrder = ['Basics', 'Sensors', 'Control', 'TeleOp', 'Encoder Based', 'Roadrunner', 'Vision', 'Miscellaneous'];

	let groups = $derived.by((): Group[] => {
		const posts: Post[] = $page.data.allPosts ?? [];
		const software = posts.filter((p) =>
			(p.meta.tags || []).some((t) => t.toLowerCase() === 'software')
		);

		const map = new Map<string, Link[]>();
		for (const p of software) {
			const tags = (p.meta.tags || []).map((t) => t.toLowerCase());
			const completed = tags.includes('completed');
			if (!completed && !devModeState.active) continue;
			const cat = p.meta.panelCategory || 'General';
			if (cat === 'Developer' && !devModeState.active) continue;
			if (!map.has(cat)) map.set(cat, []);
			map.get(cat)!.push({
				href: `/software/${p.slug}`,
				label: p.meta.title,
				devOnly: !completed
			});
		}

		const cats = [...map.keys()].sort((a, b) => {
			const ia = categoryOrder.indexOf(a);
			const ib = categoryOrder.indexOf(b);
			if (ia !== -1 || ib !== -1) return (ia === -1 ? 99 : ia) - (ib === -1 ? 99 : ib);
			return a.localeCompare(b);
		});

		return cats.map((title) => ({
			title,
			links: map.get(title)!.sort((a, b) => a.label.localeCompare(b.label))
		}));
	});

	let activeGroup = $derived(groups.find((g) => g.links.some((l) => l.href === currentPath)));

	let mobileOpen = $state(false);
	let collapsed = $state<Record<string, boolean>>({});

	function toggleGroup(title: string) {
		collapsed[title] = !collapsed[title];
	}
</script>

{#if groups.length > 0}
	{#if mobileOpen}
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_static_element_interactions -->
		<div class="mobile-backdrop" transition:fade={{ duration: 150 }} onclick={() => (mobileOpen = false)}></div>
	{/if}

	<nav class="left-sidebar" class:mobile-open={mobileOpen} aria-label="Section navigation">
		<div class="sidebar-header-mobile">
			<p class="sidebar-title">{activeGroup ? activeGroup.title : 'Software'}</p>
			<button class="close-sidebar-btn" onclick={() => (mobileOpen = false)} aria-label="Close navigation">✕</button>
		</div>
		<div class="sidebar-scroll">
			{#each groups as group}
				<div class="sidebar-group">
					<button
						class="group-toggle"
						onclick={() => toggleGroup(group.title)}
						aria-expanded={!collapsed[group.title]}
					>
						<span class="group-label">{group.title}</span>
						<svg
							class="chevron-icon"
							class:rotated={collapsed[group.title]}
							width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"
						>
							<polyline points="6 9 12 15 18 9"></polyline>
						</svg>
					</button>

					{#if !collapsed[group.title]}
						<ul class="sidebar-list" transition:slide={{ duration: 150 }}>
							{#each group.links as { href, label, devOnly }}
								<li>
									<a
										{href}
										class="sidebar-link"
										class:active={currentPath === href}
										class:dev-only={devOnly}
										aria-current={currentPath === href ? 'page' : undefined}
										onclick={() => (mobileOpen = false)}
									>
										{label}
									</a>
								</li>
							{/each}
						</ul>
					{/if}
				</div>
			{/each}
		</div>
	</nav>

	<button
		class="mobile-toggle-fab"
		onclick={() => (mobileOpen = !mobileOpen)}
		aria-label="Toggle section navigation"
		class:active={mobileOpen}
	>
		<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
			<line x1="4" y1="12" x2="20" y2="12"></line>
			<line x1="4" y1="6" x2="20" y2="6"></line>
			<line x1="4" y1="18" x2="20" y2="18"></line>
		</svg>
		<span>Menu</span>
	</button>
{/if}

<style>
	.left-sidebar {
		position: sticky;
		top: var(--header-height);
		width: 280px;
		flex-shrink: 0;
		min-height: calc(100vh - var(--header-height));
		max-height: calc(100vh - var(--header-height));
		overflow-y: auto;
		padding: 1.5rem 1rem 2rem 1.5rem;
		background: var(--sidebar-bg);
		border-right: 1px solid var(--border);
		scrollbar-width: thin;
	}

	.sidebar-scroll {
		display: flex;
		flex-direction: column;
		gap: 1.25rem;
	}

	.sidebar-header-mobile {
		display: none;
	}

	.close-sidebar-btn {
		display: none;
	}

	.group-toggle {
		display: flex;
		align-items: center;
		justify-content: space-between;
		width: 100%;
		background: none;
		border: none;
		padding: 0.25rem 0.5rem;
		cursor: pointer;
		color: var(--text-primary);
	}

	.group-label {
		font-size: 0.75rem;
		font-weight: 600;
		text-transform: uppercase;
		letter-spacing: 0.05em;
	}

	.chevron-icon {
		color: var(--text-muted);
		transition: transform var(--transition-fast);
	}

	.chevron-icon.rotated {
		transform: rotate(-90deg);
	}

	.sidebar-list {
		list-style: none;
		padding: 0;
		margin: 0.25rem 0 0;
		display: flex;
		flex-direction: column;
		border-left: 1px solid var(--border-subtle);
		margin-left: 0.5rem;
	}

	.sidebar-link {
		display: block;
		font-size: 0.85rem;
		color: var(--text-secondary);
		text-decoration: none;
		padding: 0.3rem 0.75rem;
		margin-left: -1px;
		border-left: 1px solid transparent;
		line-height: 1.4;
		transition: color var(--transition-fast), border-color var(--transition-fast);
	}

	.sidebar-link:hover {
		color: var(--text-primary);
		border-left-color: var(--text-muted);
	}

	.sidebar-link.active {
		color: var(--text-primary);
		font-weight: 600;
		border-left-color: var(--text-primary);
	}

	.sidebar-link.dev-only {
		color: var(--text-muted);
		font-style: italic;
	}

	.mobile-toggle-fab {
		display: none;
	}

	.mobile-backdrop {
		display: none;
	}

	@media (max-width: 1100px) {
		.mobile-toggle-fab {
			display: flex;
			align-items: center;
			gap: 0.5rem;
			position: fixed;
			bottom: 1.25rem;
			left: 1.25rem;
			padding: 0 1rem;
			height: 44px;
			background: var(--bg-card);
			border: 1px solid var(--border);
			color: var(--text-primary);
			font-size: 0.85rem;
			font-weight: 600;
			cursor: pointer;
			box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
			z-index: 1000;
		}

		.left-sidebar {
			position: fixed;
			top: 0;
			left: 0;
			width: min(300px, 85vw);
			height: 100vh;
			max-height: none;
			background: var(--sidebar-bg);
			z-index: 1100;
			border-right: 1px solid var(--border);
			padding: 1.25rem;
			transform: translateX(-100%);
			transition: transform var(--transition-base);
			display: flex;
			flex-direction: column;
			box-shadow: 8px 0 24px rgba(0, 0, 0, 0.2);
		}

		.left-sidebar.mobile-open {
			transform: translateX(0);
		}

		.sidebar-header-mobile {
			display: flex;
			align-items: center;
			justify-content: space-between;
			margin-bottom: 1rem;
			padding-bottom: 0.75rem;
			border-bottom: 1px solid var(--border);
		}

		.sidebar-title {
			font-size: 0.9rem;
			font-weight: 600;
			color: var(--text-primary);
		}

		.close-sidebar-btn {
			display: block;
			background: none;
			border: none;
			color: var(--text-muted);
			font-size: 1.1rem;
			cursor: pointer;
		}

		.sidebar-scroll {
			flex: 1;
			overflow-y: auto;
		}

		.sidebar-link {
			padding: 0.55rem 0.75rem;
			font-size: 0.9rem;
		}

		.mobile-backdrop {
			display: block;
			position: fixed;
			inset: 0;
			background: rgba(0, 0, 0, 0.5);
			z-index: 1050;
		}
	}
</style>
