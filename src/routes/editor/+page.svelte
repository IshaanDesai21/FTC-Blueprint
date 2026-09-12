<script lang="ts">
	import { onMount, tick } from 'svelte';
	import { marked } from 'marked';
	import { fade } from 'svelte/transition';
	import { dev, browser } from '$app/environment';

	// ─── Types ───────────────────────────────────────────────────────────────────
	interface PostMeta {
		title?: string;
		date?: string;
		panelCategory?: string;
		description?: string;
		tags?: string[];
		author?: string;
		published?: boolean;
		[key: string]: unknown;
	}
	interface PostEntry {
		slug: string;
		meta: PostMeta;
	}

	// ─── State ───────────────────────────────────────────────────────────────────
	let posts = $state<PostEntry[]>([]);
	let search = $state('');
	let filteredPosts = $derived.by(() => {
		const q = search.toLowerCase();
		if (!q) return [...posts];
		return posts.filter(
			(p) =>
				p.slug.toLowerCase().includes(q) ||
				String(p.meta.title ?? '').toLowerCase().includes(q) ||
				(p.meta.tags ?? []).some((t) => t.toLowerCase().includes(q))
		);
	});
	let activeSlug = $state<string | null>(null);
	let rawContent = $state('');
	let saveStatus = $state<'idle' | 'saving' | 'saved' | 'error'>('idle');
	let saveMsg = $state('');
	let editorTab = $state<'frontmatter' | 'content'>('content');
	let previewOpen = $state(true);
	let loadingFile = $state(false);
	let newPostSlug = $state('');
	let showNewPostDialog = $state(false);
	let newPostError = $state('');
	let uploadingImage = $state(false);
	let showImageDialog = $state(false);
	let imageAlt = $state('');
	let imageAlign = $state<'left' | 'center' | 'right'>('center');
	let imageSize = $state<'small' | 'medium' | 'large' | 'full'>('medium');
	let pendingImageUrl = $state('');
	let publishKey = $state('');
	let publishUnlocked = $derived(publishKey === 'unlock-publish');

	let editorEl = $state<HTMLTextAreaElement | null>(null);
	let imageMap = new Map<string, string>();

	function shorten(text: string): string {
		const dataUrlRegex = /data:(?:image|application|model)\/[a-zA-Z0-9+-.]+;base64,[a-zA-Z0-9+/=]+/g;
		return text.replace(dataUrlRegex, (match) => {
			const id = Math.random().toString(36).substring(2, 9);
			imageMap.set(id, match);
			return `data:asset/...#${id}`;
		});
	}

	function expand(text: string): string {
		const placeholderRegex = /data:asset\/\.\.\.#([a-z0-9]+)/g;
		return text.replace(placeholderRegex, (match, id) => {
			return imageMap.get(id) || match;
		});
	}

	// ─── Frontmatter fields ───────────────────────────────────────────────────────
	let fm = $state<PostMeta>({
		title: '',
		date: new Date().toISOString().slice(0, 10),
		panelCategory: 'NOT ASSIGNED YET',
		description: '',
		tags: [],
		author: '',
		published: false
	});
	let tagInput = $state('');

	const PRESET_TAGS = [
		'completed', 'coming soon', 'beginner', 'intermediate', 'advanced',
		'software', 'hardware', 'outreach', 'rookie', 'video'
	];

	// ─── Computed content body (without frontmatter) ──────────────────────────────
	let contentBody = $derived(() => {
		const match = rawContent.match(/^---[\s\S]*?---\r?\n([\s\S]*)$/);
		const body = match ? match[1] : rawContent;
		return expand(body);
	});


	// ─── Section grouping ─────────────────────────────────────────────────────────
	function getSection(p: PostEntry): string {
		const tags = p.meta.tags ?? [];
		if (tags.includes('hardware')) return 'Hardware';
		if (tags.includes('outreach')) return 'Outreach';
		return 'Software';
	}

	let grouped = $derived.by(() => {
		const g: Record<string, PostEntry[]> = {};
		for (const p of filteredPosts) {
			const s = getSection(p);
			(g[s] ??= []).push(p);
		}
		return g;
	});

	function toggleTag(tag: string) {
		const t = tag.toLowerCase();
		if ((fm.tags ?? []).includes(t)) {
			fm.tags = (fm.tags ?? []).filter((x) => x !== t);
		} else {
			fm.tags = [...(fm.tags ?? []), t];
		}
	}

	// ─── Load posts list ──────────────────────────────────────────────────────────
	async function loadPosts() {
		if (!browser) return;
		if (dev) {
			const r = await fetch('/api/list-posts');
			const data = await r.json();
			posts = data.posts ?? [];
		} else {
			const stored = localStorage.getItem('blueprint_posts');
			posts = stored ? JSON.parse(stored) : [];
		}
	}

	// ─── Open a post ─────────────────────────────────────────────────────────────
	async function openPost(slug: string) {
		if (saveStatus === 'saving') return;
		loadingFile = true;
		activeSlug = slug;
		editorTab = 'content';
		rawContent = '';
		saveStatus = 'idle';
		try {
			if (dev) {
				const r = await fetch(`/api/get-local?slug=${encodeURIComponent(slug)}`);
				if (!r.ok) throw new Error(await r.text());
				const d = await r.json();
				imageMap.clear();
				rawContent = shorten(d.content);
			} else {
				const content = localStorage.getItem(`blueprint_post_${slug}`);
				if (content === null) throw new Error('Post not found in storage');
				imageMap.clear();
				rawContent = shorten(content);
			}
			parseFM(rawContent);
		} catch (e) {
			saveMsg = e instanceof Error ? e.message : 'Failed to load file';
			saveStatus = 'error';
		} finally {
			loadingFile = false;
		}
	}

	// ─── Parse frontmatter into fm state ──────────────────────────────────────────
	function parseFM(raw: string) {
		const match = raw.match(/^---\r?\n([\s\S]*?)\r?\n---/);
		if (!match) return;
		const obj: PostMeta = {};
		for (const line of match[1].split(/\r?\n/)) {
			const colonIdx = line.indexOf(':');
			if (colonIdx === -1) continue;
			const key = line.slice(0, colonIdx).trim();
			let val: unknown = line.slice(colonIdx + 1).trim();
			if (typeof val === 'string' && val.startsWith('[')) {
				val = val
					.replace(/^\[|\]$/g, '')
					.split(',')
					.map((s) => s.trim().replace(/^["']|["']$/g, ''))
					.filter(Boolean);
			} else if (val === 'true') val = true;
			else if (val === 'false') val = false;
			obj[key] = val;
		}
		fm = {
			title: String(obj.title ?? ''),
			date: String(obj.date ?? new Date().toISOString().slice(0, 10)),
			panelCategory: String(obj.panelCategory ?? 'NOT ASSIGNED YET'),
			description: String(obj.description ?? ''),
			tags: Array.isArray(obj.tags) ? (obj.tags as string[]) : [],
			author: String(obj.author ?? ''),
			published: Boolean(obj.published)
		};
	}

	// ─── Serialize frontmatter + body back into rawContent ───────────────────────
	function buildRaw(): string {
		// Strip old frontmatter
		const body = rawContent.replace(/^---[\s\S]*?---\r?\n?/, '');
		const tagLine = `[${(fm.tags ?? []).map((t) => `"${t}"`).join(', ')}]`;
		return [
			'---',
			`title: ${fm.title ?? ''}`,
			`date: ${fm.date ?? ''}`,
			`panelCategory: "${fm.panelCategory ?? ''}"`,
			`description: ${fm.description ?? ''}`,
			`tags: ${tagLine}`,
			`author: ${fm.author ?? ''}`,
			`published: ${fm.published ?? false}`,
			'---',
			'',
			body.replace(/^\n+/, '')
		].join('\n');
	}

	// ─── Save ─────────────────────────────────────────────────────────────────────
	async function save() {
		if (!activeSlug || saveStatus === 'saving') return;

		// Validation: Requires at least one core category tag
		const requiredTags = ['software', 'hardware', 'outreach'];
		const hasCategory = (fm.tags ?? []).some(t => requiredTags.includes(t.toLowerCase()));
		
		if (!hasCategory) {
			saveStatus = 'error';
			saveMsg = 'Tag required: software, hardware, or outreach (See Frontmatter tab)';
			editorTab = 'frontmatter'; // Switch to Frontmatter tab
			return;
		}

		saveStatus = 'saving';
		saveMsg = 'Saving…';
		const expanded = expand(rawContent);
		const body = expanded.replace(/^---[\s\S]*?---\r?\n?/, '');
		const tagLine = `[${(fm.tags ?? []).map((t) => `"${t}"`).join(', ')}]`;
		const finalContent = [
			'---',
			`title: ${fm.title ?? ''}`,
			`date: ${fm.date ?? ''}`,
			`panelCategory: "${fm.panelCategory ?? ''}"`,
			`description: ${fm.description ?? ''}`,
			`tags: ${tagLine}`,
			`author: ${fm.author ?? ''}`,
			`published: ${fm.published ?? false}`,
			'---',
			'',
			body.replace(/^\n+/, '')
		].join('\n');

		try {
			if (dev) {
				const r = await fetch('/api/save-local', {
					method: 'POST',
					headers: { 'Content-Type': 'application/json' },
					body: JSON.stringify({ slug: activeSlug, content: finalContent })
				});
				if (!r.ok) throw new Error(await r.text());
			} else {
				localStorage.setItem(`blueprint_post_${activeSlug}`, finalContent);
				// Update index if needed
				const entry = posts.find(p => p.slug === activeSlug);
				if (entry) {
					entry.meta = { ...fm };
					localStorage.setItem('blueprint_posts', JSON.stringify(posts));
				}
			}
			rawContent = finalContent;
			await loadPosts();
			saveStatus = 'saved';
			saveMsg = 'Saved ✓';
			setTimeout(() => { if (saveStatus === 'saved') { saveStatus = 'idle'; saveMsg = ''; } }, 2000);
		} catch (e) {
			saveStatus = 'error';
			saveMsg = 'Save failed';
		}
	}

	function exportTxt() {
		if (!activeSlug) return;
		const full = buildRaw();
		const blob = new Blob([full], { type: 'text/plain' });
		const url = URL.createObjectURL(blob);
		const a = Object.assign(document.createElement('a'), {
			href: url,
			download: `${activeSlug}.txt`
		});
		a.click();
		URL.revokeObjectURL(url);
	}

	// ─── Keyboard shortcuts ────────────────────────────────────────────────────────
	function handleKeydown(e: KeyboardEvent) {
		if ((e.metaKey || e.ctrlKey) && (e.key === 's' || e.key === 'Enter')) {
			e.preventDefault();
			save();
		}
		if (e.key === 'Tab' && editorTab === 'content') {
			e.preventDefault();
			const el = e.target as HTMLTextAreaElement;
			const start = el.selectionStart;
			const end = el.selectionEnd;
			rawContent = rawContent.substring(0, start) + '  ' + rawContent.substring(end);
			setTimeout(() => { el.selectionStart = el.selectionEnd = start + 2; }, 0);
		}
	}

	// ─── Toolbar insert ────────────────────────────────────────────────────────────
	function insertAtCursor(before: string, after = '') {
		if (!editorEl) return;
		const start = editorEl.selectionStart;
		const end = editorEl.selectionEnd;
		const selected = rawContent.substring(start, end);
		const replacement = before + (selected || 'text') + after;
		rawContent = rawContent.substring(0, start) + replacement + rawContent.substring(end);
		setTimeout(() => {
			if (!editorEl) return;
			editorEl.selectionStart = start + before.length;
			editorEl.selectionEnd = start + before.length + (selected || 'text').length;
			editorEl.focus();
		}, 0);
	}

	function insertRaw(text: string) {
		if (!editorEl) { rawContent += text; return; }
		const start = editorEl.selectionStart;
		rawContent = rawContent.substring(0, start) + text + rawContent.substring(start);
		setTimeout(() => {
			if (!editorEl) return;
			editorEl.selectionStart = editorEl.selectionEnd = start + text.length;
			editorEl.focus();
		}, 0);
	}

	// ─── Image/File upload ─────────────────────────────────────────────────────────
	async function uploadFile(file: File) {
		if (!activeSlug) { alert('Open a post first.'); return; }
		uploadingImage = true;
		const isModel = file.name.endsWith('.glb') || file.name.endsWith('.gltf');
		const subfolder = isModel ? 'models' : 'images';
		
		try {
			const reader = new FileReader();
			const fullDataUrl = await new Promise<string>((resolve) => {
				reader.onload = () => resolve(reader.result as string);
				reader.readAsDataURL(file);
			});

			let finalUrl = '';
			const base64Data = fullDataUrl.split(',')[1];
			const safeName = file.name.replace(/[^a-z0-9._-]/gi, '_').toLowerCase();
			const uniqueName = `${Date.now()}_${safeName}`;

			if (dev) {
				const r = await fetch('/api/upload-file', {
					method: 'POST',
					headers: { 'Content-Type': 'application/json' },
					body: JSON.stringify({ slug: activeSlug, fileName: uniqueName, base64Data })
				});
				const d = await r.json();
				finalUrl = d.url || '';
			} else {
				// PRODUCTION: Upload to GitHub directly
				const GITHUB_TOKEN = import.meta.env.VITE_GITHUB_TOKEN || ''; // This should be provided or handled via API
				// Note: Since we are in the main editor page, we use the GITHUB_OWNER logic similar to MarkdownEditor
				const GITHUB_OWNER = 'idesai-dev';
				const GITHUB_REPO = 'FTC-Blueprint';
				
				if (GITHUB_TOKEN) {
					await fetch(
						`https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/static/${subfolder}/posts/${activeSlug}/${uniqueName}`,
						{
							method: 'PUT',
							headers: { Authorization: `Bearer ${GITHUB_TOKEN}`, Accept: 'application/vnd.github.v3+json', 'Content-Type': 'application/json' },
							body: JSON.stringify({ message: `docs: upload ${isModel ? 'model' : 'image'} for ${activeSlug}`, content: base64Data })
						}
					);
				}
				finalUrl = `/${subfolder}/posts/${activeSlug}/${uniqueName}`;
			}
			
			if (isModel) {
				let url = finalUrl;
				if (url.startsWith('data:')) {
					const id = Math.random().toString(36).substring(2, 9);
					imageMap.set(id, url);
					url = `data:asset/...#${id}`;
				}
				const html = `\n<model-viewer src="${url}" camera-controls auto-rotate shadow-intensity="1" style="width: 100%; height: 400px; background: #1a1a1a; border-radius: 0;"></model-viewer>\n`;
				insertRaw(html);
			} else {
				pendingImageUrl = finalUrl;
				imageAlt = file.name.replace(/\.[^/.]+$/, '').replace(/[_-]/g, ' ');
				showImageDialog = true;
			}
		} catch (e) {
			console.error(e);
			alert('Upload failed.');
		} finally {
			uploadingImage = false;
		}
	}

	async function handlePasteInEditor(e: ClipboardEvent) {
		for (const item of Array.from(e.clipboardData?.items ?? [])) {
			if (item.type.startsWith('image/')) {
				const file = item.getAsFile();
				if (file) { e.preventDefault(); await uploadFile(file); }
			}
		}
	}

	async function handleDropInEditor(e: DragEvent) {
		e.preventDefault();
		for (const file of Array.from(e.dataTransfer?.files ?? [])) {
			const isImage = file.type.startsWith('image/');
			const isModel = file.name.endsWith('.glb') || file.name.endsWith('.gltf');
			if (isImage || isModel) await uploadFile(file);
		}
	}

	function confirmImageInsert() {
		const sizeMap = { small: '240px', medium: '480px', large: '720px', full: '100%' };
		const alignMap = { left: 'margin-right: auto;', center: 'margin: 0 auto;', right: 'margin-left: auto;' };
		const w = sizeMap[imageSize];
		const m = alignMap[imageAlign];
		
		let url = pendingImageUrl;
		if (url.startsWith('data:')) {
			const id = Math.random().toString(36).substring(2, 9);
			imageMap.set(id, url);
			url = `data:asset/...#${id}`;
		}
		
		const html = `\n<img src="${url}" alt="${imageAlt}" style="width: ${w}; ${m} display: block; border-radius: 0;" />\n`;
		insertRaw(html);
		showImageDialog = false;
		pendingImageUrl = '';
		imageAlt = '';
	}

	// ─── Tag helpers ───────────────────────────────────────────────────────────────
	function addTag(tag: string) {
		tag = tag.trim();
		if (!tag || fm.tags?.includes(tag)) return;
		fm = { ...fm, tags: [...(fm.tags ?? []), tag] };
		tagInput = '';
	}

	function removeTag(tag: string) {
		fm = { ...fm, tags: (fm.tags ?? []).filter((t) => t !== tag) };
	}

	// ─── New post ──────────────────────────────────────────────────────────────────
	async function createPost() {
		newPostError = '';
		const slug = newPostSlug.trim();
		if (!slug || !/^[a-z0-9-]+$/.test(slug)) {
			newPostError = 'Invalid slug: use only lowercase letters, numbers, and hyphens.';
			return;
		}
		
		try {
			if (dev) {
				const r = await fetch('/api/create-post', {
					method: 'POST',
					headers: { 'Content-Type': 'application/json' },
					body: JSON.stringify({ slug })
				});
				const d = await r.json();
				if (!r.ok) { newPostError = d.message || 'Error'; return; }
			} else {
				if (posts.some(p => p.slug === slug)) {
					newPostError = 'A post with that slug already exists.';
					return;
				}
				const today = new Date().toISOString().slice(0, 10);
				const title = slug.replace(/-/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
				const stub = `---
title: ${title}
date: ${today}
panelCategory: "NOT ASSIGNED YET"
description: 
tags: []
author: 
published: false
---

Start writing here...
`;
				localStorage.setItem(`blueprint_post_${slug}`, stub);
				const newEntry: PostEntry = { slug, meta: { title, date: today, panelCategory: 'NOT ASSIGNED YET', tags: [], published: false } };
				posts = [newEntry, ...posts];
				localStorage.setItem('blueprint_posts', JSON.stringify(posts));
			}
			
			await loadPosts();
			showNewPostDialog = false;
			newPostSlug = '';
			openPost(slug);
		} catch {
			newPostError = 'Network error';
		}
	}

	// ─── Word + char count ─────────────────────────────────────────────────────────
	let wordCount = $derived(() => {
		const body = rawContent.replace(/^---[\s\S]*?---\r?\n?/, '');
		return body.trim().split(/\s+/).filter(Boolean).length;
	});

	// ─── Init ──────────────────────────────────────────────────────────────────────
	onMount(loadPosts);
</script>

<svelte:head>
	<title>Blueprint Editor</title>
</svelte:head>

<svelte:window onkeydown={handleKeydown} />

<!-- ══════════════════════════════════════════════════════════════════════════════
     LAYOUT
══════════════════════════════════════════════════════════════════════════════ -->
<div class="editor-shell">

	<!-- ── LEFT SIDEBAR - File Browser ── -->
	<aside class="sidebar">
		<div class="sidebar-top">
			<div class="sidebar-brand">
				<span class="brand-dot"></span>
				<span>Blueprint <em>Editor</em></span>
			</div>
			<button class="new-post-btn" onclick={() => (showNewPostDialog = true)} title="New Post">
				<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
					<line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
				</svg>
				New
			</button>
		</div>
		<div class="search-wrap">
			<svg class="search-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
				<circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
			</svg>
			<input class="search-input" bind:value={search} placeholder="Search posts…" type="search" />
		</div>

		<nav class="file-list">
			{#each Object.entries(grouped) as [section, entries]}
				<div class="section-group">
					<div class="section-label">{section}</div>
					{#each entries as post}
						<button
							class="file-item"
							class:active={activeSlug === post.slug}
							onclick={() => openPost(post.slug)}
						>
							<span class="file-name">{post.meta.title || post.slug}</span>
							<span class="file-slug">{post.slug}</span>
							{#if post.meta.published}
								<span class="pub-dot" title="Published"></span>
							{/if}
						</button>
					{/each}
				</div>
			{/each}
			{#if filteredPosts.length === 0}
				<div class="empty-list">No posts found</div>
			{/if}
		</nav>
	</aside>

	<!-- ── CENTRE - Editor ── -->
	<main class="editor-main">
		{#if !activeSlug}
			<div class="empty-state">
				<svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" stroke-linecap="round" stroke-linejoin="round" opacity="0.3">
					<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/>
				</svg>
				<p>Select a post to edit</p>
				<p class="hint">or create a new one →</p>
			</div>
		{:else if loadingFile}
			<div class="empty-state">
				<div class="spinner"></div>
				<p>Loading…</p>
			</div>
		{:else}
			<!-- Tab bar -->
			<div class="editor-topbar">
				<div class="tab-group">
					<button class="tab-btn" class:active={editorTab === 'frontmatter'} onclick={() => (editorTab = 'frontmatter')}>
						<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14M4.93 4.93a10 10 0 0 0 0 14.14"/></svg>
						Frontmatter
					</button>
					<button class="tab-btn" class:active={editorTab === 'content'} onclick={() => (editorTab = 'content')}>
						<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="17" y1="10" x2="3" y2="10"/><line x1="21" y1="6" x2="3" y2="6"/><line x1="21" y1="14" x2="3" y2="14"/><line x1="13" y1="18" x2="3" y2="18"/></svg>
						Content
					</button>
				</div>
				<div class="topbar-right">
					<span class="slug-pill">{activeSlug}.md</span>
					<button class="toggle-preview-btn" onclick={() => (previewOpen = !previewOpen)} title="Toggle preview">
						{previewOpen ? 'Hide Preview' : 'Show Preview'}
					</button>
					<button class="export-btn" onclick={exportTxt} title="Export as .txt">
						<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
							<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/>
						</svg>
						Export
					</button>
					<button class="save-btn" onclick={save} disabled={saveStatus === 'saving'}>
						{#if saveStatus === 'saving'}Saving…{:else if saveStatus === 'saved'}Saved ✓{:else if saveStatus === 'error'}Error!{:else}Save <kbd>⌘S</kbd>{/if}
					</button>
				</div>
			</div>

			<!-- Tab content -->
			<div class="editor-body" class:split={previewOpen && editorTab === 'content'}>

				<!-- ── FRONTMATTER TAB ── -->
				{#if editorTab === 'frontmatter'}
					<div class="fm-panel">
						<div class="fm-grid">
							<label class="fm-label" for="fm-title">Title</label>
							<input id="fm-title" class="fm-input" bind:value={fm.title} placeholder="Post title…" />

							<label class="fm-label" for="fm-date">Date</label>
							<input id="fm-date" class="fm-input" type="date" bind:value={fm.date} />

							<label class="fm-label" for="fm-author">Author</label>
							<input id="fm-author" class="fm-input" bind:value={fm.author} placeholder="Your name…" />

							<label class="fm-label" for="fm-category">Left Panel Collapsible Category Name</label>
							<input id="fm-category" class="fm-input" bind:value={fm.panelCategory} placeholder="Basics, Sensors, Vision..." />

							<label class="fm-label" for="fm-desc">Description</label>
							<textarea id="fm-desc" class="fm-input fm-textarea" bind:value={fm.description} rows="2" placeholder="Short summary…"></textarea>

							<span class="fm-label">Tags</span>
							<div class="tag-editor">
								<div class="tag-chips">
									{#each fm.tags ?? [] as tag}
										<span class="chip">
											{tag}
											<button class="chip-x" onclick={() => removeTag(tag)}>×</button>
										</span>
									{/each}
								</div>
								<div class="tag-input-row">
									<input
										class="fm-input tag-inp"
										bind:value={tagInput}
										placeholder="Add tag…"
										onkeydown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addTag(tagInput); }}}
									/>
									<button class="tag-add-btn" onclick={() => addTag(tagInput)}>Add</button>
								</div>
								<div class="preset-tags">
									{#each PRESET_TAGS as preset}
										<button
											type="button"
											class="preset-tag"
											class:used={(fm.tags ?? []).includes(preset)}
											onclick={() => toggleTag(preset)}
										>{preset}</button>
									{/each}
								</div>
							</div>

							<span class="fm-label">Published</span>
							<div class="publish-row">
								{#if publishUnlocked}
									<label class="toggle-wrap">
										<input type="checkbox" bind:checked={fm.published} />
										<span class="toggle-track"><span class="toggle-thumb"></span></span>
										<span class="toggle-label">{fm.published ? 'true' : 'false'}</span>
									</label>
								{:else}
									<span class="locked-badge">🔒 locked, always <code>false</code></span>
								{/if}
								<div class="unlock-row">
									<input class="unlock-input" type="password" bind:value={publishKey} placeholder="Enter key to unlock…" />
									{#if publishUnlocked}
										<span class="unlocked-label">✓ Unlocked</span>
									{/if}
								</div>
							</div>
						</div>

						<button class="apply-fm-btn" onclick={() => { rawContent = buildRaw(); editorTab = 'content'; }}>
							Apply &amp; Go to Content →
						</button>
					</div>

				<!-- ── CONTENT TAB ── -->
				{:else}
					<!-- Toolbar -->
					<div class="toolbar" class:full={!previewOpen}>
						<button class="tool-btn" onclick={() => insertAtCursor('**', '**')} title="Bold"><b>B</b></button>
						<button class="tool-btn" onclick={() => insertAtCursor('*', '*')} title="Italic"><em>I</em></button>
						<button class="tool-btn" onclick={() => insertAtCursor('~~', '~~')} title="Strike"><s>S</s></button>
						<span class="tool-sep"></span>
						<button class="tool-btn" onclick={() => insertAtCursor('# ')} title="H1">H1</button>
						<button class="tool-btn" onclick={() => insertAtCursor('## ')} title="H2">H2</button>
						<button class="tool-btn" onclick={() => insertAtCursor('### ')} title="H3">H3</button>
						<span class="tool-sep"></span>
						<button class="tool-btn" onclick={() => insertAtCursor('[', '](url)')} title="Link">🔗</button>
						<button class="tool-btn" onclick={() => insertRaw('\n```\n\n```\n')} title="Code block">&lt;/&gt;</button>
						<button class="tool-btn" onclick={() => insertAtCursor('`', '`')} title="Inline code"><code>``</code></button>
						<button class="tool-btn" onclick={() => insertRaw('\n> ')} title="Quote">"</button>
						<button class="tool-btn" onclick={() => insertRaw('\n- ')} title="List">• List</button>
						<button class="tool-btn" onclick={() => insertRaw('\n1. ')} title="Numbered list">1. List</button>
						<button class="tool-btn" onclick={() => insertRaw('\n| Col | Col |\n|-----|-----|\n| val | val |\n')} title="Table">Table</button>
						<span class="tool-sep"></span>
						<!-- Image upload -->
						<label class="tool-btn upload-lbl" title="Upload image or 3D model">
							{#if uploadingImage}
								<span class="mini-spin"></span>
							{:else}
								Upload
							{/if}
							<input
								type="file"
								accept="image/*, .glb, .gltf"
								class="hidden-file"
								onchange={async (e) => {
									const f = (e.target as HTMLInputElement).files?.[0];
									if (f) await uploadFile(f);
									(e.target as HTMLInputElement).value = '';
								}}
							/>
						</label>
					</div>

					<!-- Editor + optional preview -->
					<div class="content-pane">
						<div class="textarea-wrap" class:half={previewOpen}>
							<textarea
								class="md-textarea"
								bind:this={editorEl}
								bind:value={rawContent}
								onpaste={handlePasteInEditor}
								ondrop={handleDropInEditor}
								ondragover={(e) => e.preventDefault()}
								spellcheck={false}
								placeholder="Write markdown… paste or drop images here"
							></textarea>
						</div>
						{#if previewOpen}
							<div class="preview-pane" transition:fade={{ duration: 150 }}>
								<div class="preview-inner prose">
									{@html marked.parse(contentBody())}
								</div>
							</div>
						{/if}
					</div>
				{/if}
			</div>

			<!-- Bottom bar -->
			<div class="bottom-bar">
				<span class="word-count">{wordCount()} words</span>
				{#if saveMsg}
					<span class="save-status-msg" class:error={saveStatus === 'error'} class:ok={saveStatus === 'saved'}>{saveMsg}</span>
				{/if}
				<span class="hint-text">Ctrl/Cmd+S to save · paste images directly · drop files to upload</span>
			</div>
		{/if}
	</main>
</div>

<!-- ══════════════════════════════════════════════════════════════════════════════
     NEW POST DIALOG
══════════════════════════════════════════════════════════════════════════════ -->
{#if showNewPostDialog}
	<div 
		class="dialog-backdrop" 
		transition:fade={{ duration: 120 }} 
		onclick={(e) => { if (e.target === e.currentTarget) showNewPostDialog = false; }}
		role="button"
		tabindex="-1"
		onkeydown={(e) => { if (e.key === 'Escape') showNewPostDialog = false; }}
	>
		<div class="dialog">
			<div class="dialog-header">
				<span>New Post</span>
				<button class="dialog-close" onclick={() => (showNewPostDialog = false)}>✕</button>
			</div>
			<div class="dialog-body">
				<label class="fm-label" for="new-slug">Slug (URL path)</label>
				<input
					id="new-slug"
					class="fm-input"
					bind:value={newPostSlug}
					placeholder="my-new-post"
					onkeydown={(e) => e.key === 'Enter' && createPost()}
				/>
				<p class="slug-hint">lowercase letters, numbers, and hyphens only</p>
				<div class="naming-reminder" transition:fade>
					<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
						<circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>
					</svg>
					<span>Prefix <strong>outreach-</strong> for outreach or <strong>hardware-</strong> for hardware.</span>
				</div>
				{#if newPostError}<p class="dialog-error">{newPostError}</p>{/if}
			</div>
			<div class="dialog-footer">
				<button class="cancel-btn" onclick={() => (showNewPostDialog = false)}>Cancel</button>
				<button class="save-btn" onclick={createPost}>Create Post</button>
			</div>
		</div>
	</div>
{/if}

<!-- ══════════════════════════════════════════════════════════════════════════════
     IMAGE INSERT DIALOG
══════════════════════════════════════════════════════════════════════════════ -->
{#if showImageDialog}
	<div 
		class="dialog-backdrop" 
		transition:fade={{ duration: 120 }} 
		onclick={(e) => { if (e.target === e.currentTarget) { showImageDialog = false; } }}
		role="button"
		tabindex="-1"
		onkeydown={(e) => { if (e.key === 'Escape') showImageDialog = false; }}
	>
		<div class="dialog">
			<div class="dialog-header">
				<span>Insert Image</span>
				<button class="dialog-close" onclick={() => (showImageDialog = false)}>✕</button>
			</div>
			<div class="dialog-body">
				<div class="img-preview-wrap">
					<img src={pendingImageUrl} alt="Upload preview" class="img-preview" />
				</div>

				<label class="fm-label" for="img-alt">Alt text</label>
				<input id="img-alt" class="fm-input" bind:value={imageAlt} placeholder="Describe the image…" />

				<span class="fm-label">Alignment</span>
				<div class="btn-group">
					{#each ['left','center','right'] as a}
						<button class="seg-btn" class:active={imageAlign === a} onclick={() => (imageAlign = a as typeof imageAlign)}>{a}</button>
					{/each}
				</div>

				<span class="fm-label">Size</span>
				<div class="btn-group">
					{#each ['small','medium','large','full'] as s}
						<button class="seg-btn" class:active={imageSize === s} onclick={() => (imageSize = s as typeof imageSize)}>{s}</button>
					{/each}
				</div>
			</div>
			<div class="dialog-footer">
				<button class="cancel-btn" onclick={() => (showImageDialog = false)}>Cancel</button>
				<button class="save-btn" onclick={confirmImageInsert}>Insert Image</button>
			</div>
		</div>
	</div>
{/if}

<style>
	/* ── Shell ─────────────────────────────────────────────────────────────────── */
	:global(body) { margin: 0; overflow: hidden; }

	.editor-shell {
		display: flex;
		height: 100vh;
		width: 100vw;
		background: var(--bg);
		color: var(--text-body);
		font-family: 'Inter', system-ui, sans-serif;
		font-size: 14px;
		overflow: hidden;
	}

	/* ── Sidebar ─────────────────────────────────────────────────────────────────── */
	.sidebar {
		width: 240px;
		min-width: 200px;
		max-width: 300px;
		flex-shrink: 0;
		display: flex;
		flex-direction: column;
		background: var(--bg-secondary);
		border-right: 1px solid var(--border-subtle);
		overflow: hidden;
	}

	.sidebar-top {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 14px 12px 10px;
		border-bottom: 1px solid var(--border);
		gap: 8px;
	}

	.sidebar-brand {
		display: flex;
		align-items: center;
		gap: 8px;
		font-weight: 700;
		font-size: 13px;
		color: var(--text-primary);
		letter-spacing: -0.01em;
	}

	.sidebar-brand em { color: var(--accent-cyan); font-style: normal; }

	.brand-dot {
		width: 8px; height: 8px;
		background: var(--accent-cyan);
		border-radius: 50%;
		box-shadow: 0 0 8px var(--accent-cyan-dim);
	}

	.new-post-btn {
		display: flex;
		align-items: center;
		gap: 5px;
		background: var(--accent-cyan-dim);
		border: 1px solid var(--accent-cyan-dim);
		border-radius: 0;
		padding: 4px 10px;
		color: var(--accent-cyan);
		font-size: 12px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.15s;
		white-space: nowrap;
	}
	.new-post-btn:hover { background: var(--accent-cyan-dim); border-color: var(--accent-cyan); }

	.search-wrap {
		position: relative;
		padding: 8px 10px;
		border-bottom: 1px solid var(--border);
	}
	.search-icon {
		position: absolute;
		left: 18px;
		top: 50%;
		transform: translateY(-50%);
		color: var(--text-muted);
		pointer-events: none;
	}
	.search-input {
		width: 100%;
		background: var(--bg-card-hover);
		border: 1px solid var(--border);
		border-radius: 0;
		padding: 6px 10px 6px 28px;
		color: var(--text-body);
		font-size: 12px;
		outline: none;
		box-sizing: border-box;
	}
	.search-input:focus { border-color: var(--accent-cyan); }
	.search-input::placeholder { color: var(--text-muted); }

	.file-list {
		flex: 1;
		overflow-y: auto;
		padding: 6px 0;
	}


	.section-group { margin-bottom: 24px; }
	.section-label {
		font-size: 11px;
		font-weight: 800;
		color: var(--text-muted);
		text-transform: uppercase;
		letter-spacing: 0.12em;
		padding: 0 16px;
		margin-bottom: 10px;
		display: flex;
		align-items: center;
		gap: 8px;
	}
	.section-label::after {
		content: '';
		flex: 1;
		height: 1px;
		background: var(--border-subtle);
		opacity: 0.5;
	}

	.file-item {
		display: flex;
		flex-direction: column;
		width: 100%;
		padding: 7px 12px;
		background: none;
		border: none;
		text-align: left;
		cursor: pointer;
		transition: background 0.1s;
		position: relative;
	}
	.file-item:hover { background: var(--bg-card-hover); }
	.file-item.active { background: var(--accent-cyan-dim); }
	.file-item.active .file-name { color: var(--accent-cyan); }

	.file-name {
		font-size: 12.5px;
		font-weight: 500;
		color: var(--text-body);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		line-height: 1.3;
	}

	.file-slug {
		font-size: 10px;
		color: var(--text-muted);
		font-family: monospace;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		margin-top: 1px;
	}

	.pub-dot {
		position: absolute;
		right: 10px;
		top: 50%;
		transform: translateY(-50%);
		width: 6px; height: 6px;
		background: var(--accent-green);
		border-radius: 50%;
	}

	.empty-list { padding: 16px 12px; color: var(--text-muted); font-size: 12px; }

	/* ── Main editor ─────────────────────────────────────────────────────────────── */
	.editor-main {
		flex: 1;
		display: flex;
		flex-direction: column;
		overflow: hidden;
	}

	.empty-state {
		flex: 1;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 12px;
		color: var(--text-muted);
		height: 100%;
	}
	.empty-state p { margin: 0; font-size: 14px; }
	.empty-state .hint { font-size: 12px; color: var(--border); }

	.editor-topbar {
		display: flex;
		align-items: center;
		justify-content: space-between;
		background: var(--bg-card);
		border-bottom: 1px solid var(--border-subtle);
		padding: 0 12px;
		height: 44px;
		gap: 8px;
		flex-shrink: 0;
	}

	.tab-group { display: flex; gap: 4px; }

	.tab-btn {
		display: flex;
		align-items: center;
		gap: 6px;
		background: none;
		border: 1px solid transparent;
		border-radius: 0;
		padding: 5px 12px;
		color: var(--text-secondary);
		font-size: 12.5px;
		font-weight: 500;
		cursor: pointer;
		transition: all 0.15s;
		height: 30px;
	}
	.tab-btn:hover { color: var(--text-primary); background: var(--bg-card-hover); }
	.tab-btn.active { color: var(--text-body); background: var(--border-subtle); border-color: var(--border); }

	.topbar-right {
		display: flex;
		align-items: center;
		gap: 8px;
	}

	.slug-pill {
		font-family: monospace;
		font-size: 11px;
		color: var(--text-muted);
		background: var(--bg-card-hover);
		border: 1px solid var(--border);
		border-radius: 0;
		padding: 2px 8px;
	}

	.toggle-preview-btn {
		background: none;
		border: 1px solid var(--border);
		border-radius: 0;
		padding: 4px 10px;
		color: var(--text-secondary);
		font-size: 11.5px;
		cursor: pointer;
		transition: all 0.15s;
	}
	.toggle-preview-btn:hover { color: var(--text-primary); border-color: var(--text-muted); }

	.export-btn {
		background: none;
		border: 1px solid var(--accent-cyan-dim);
		border-radius: 0;
		padding: 5px 12px;
		color: var(--accent-cyan);
		font-size: 12px;
		font-weight: 600;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 6px;
		transition: all 0.15s;
		height: 30px;
	}
	.export-btn:hover { background: var(--accent-cyan-dim); color: var(--accent-cyan); border-color: var(--accent-cyan); }
	
	.save-btn {
		background: var(--accent-cyan);
		color: #000;
		border: none;
		border-radius: 0;
		padding: 5px 14px;
		font-weight: 700;
		font-size: 12px;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 5px;
		transition: transform 0.1s, opacity 0.15s, box-shadow 0.2s;
		height: 30px;
	}
	:global(html.light) .save-btn { color: #fff; background: var(--accent-cyan); }
	.save-btn:hover { opacity: 0.9; transform: translateY(-1px); box-shadow: 0 4px 12px rgba(116, 215, 237, 0.2); }
	.save-btn:active { transform: translateY(0); }
	.save-btn:disabled { opacity: 0.5; cursor: not-allowed; transform: none; }

	.save-btn kbd {
		background: rgba(0, 0, 0, 0.1);
		border-radius: 0;
		padding: 0 4px;
		font-size: 10px;
		opacity: 0.7;
	}

	/* ── Editor body ─────────────────────────────────────────────────────────────── */
	.editor-body {
		flex: 1;
		display: flex;
		flex-direction: column;
		overflow: hidden;
	}

	/* ── Frontmatter panel ───────────────────────────────────────────────────────── */
	.fm-panel {
		flex: 1;
		overflow-y: auto;
		padding: 24px 32px;
		display: flex;
		flex-direction: column;
		gap: 0;
	}

	.fm-grid {
		display: grid;
		grid-template-columns: 120px 1fr;
		gap: 14px 16px;
		align-items: start;
		max-width: 680px;
		margin-bottom: 20px;
	}

	.fm-label {
		font-size: 12px;
		font-weight: 600;
		color: var(--text-secondary);
		text-transform: uppercase;
		letter-spacing: 0.04em;
		padding-top: 8px;
	}

	.fm-input {
		background: var(--bg-card-hover);
		border: 1px solid var(--border);
		border-radius: 0;
		padding: 8px 12px;
		color: var(--text-body);
		font-size: 13px;
		font-family: inherit;
		outline: none;
		width: 100%;
		box-sizing: border-box;
		transition: border-color 0.15s;
	}
	.fm-input:focus { border-color: var(--accent-cyan); }
	.fm-textarea { resize: vertical; min-height: 56px; }

	.tag-editor { display: flex; flex-direction: column; gap: 8px; }
	.tag-chips { display: flex; flex-wrap: wrap; gap: 6px; min-height: 24px; }
	.chip {
		display: flex; align-items: center; gap: 4px;
		background: var(--accent-cyan-dim); border: 1px solid var(--accent-cyan-dim);
		color: var(--accent-cyan); padding: 3px 10px; border-radius: 0; font-size: 11.5px;
	}
	.chip-x {
		background: none; border: none; color: inherit;
		cursor: pointer; font-size: 13px; line-height: 1; opacity: 0.6; padding: 0;
	}
	.chip-x:hover { opacity: 1; }

	.tag-input-row { display: flex; gap: 6px; }
	.tag-inp { flex: 1; }

	.tag-add-btn {
		background: var(--border);
		border: 1px solid var(--border);
		border-radius: 0;
		padding: 7px 14px;
		color: var(--text-secondary);
		font-size: 12px;
		font-weight: 600;
		cursor: pointer;
	}
	.tag-add-btn:hover { color: var(--text-body); border-color: var(--text-muted); }

	.preset-tags { display: flex; flex-wrap: wrap; gap: 5px; }

	.preset-tag {
		background: var(--bg-card-hover);
		border: 1px solid var(--border);
		border-radius: 0;
		padding: 3px 10px;
		font-size: 11px;
		color: var(--text-secondary);
		cursor: pointer;
		transition: all 0.15s;
	}
	.preset-tag:hover { color: var(--text-primary); border-color: var(--text-muted); }
	.preset-tag.used {
		background: var(--accent-cyan-dim);
		border-color: var(--accent-cyan-dim);
		color: var(--accent-cyan);
	}

	.publish-row { display: flex; flex-direction: column; gap: 8px; }

	.toggle-wrap {
		display: flex;
		align-items: center;
		gap: 8px;
		cursor: pointer;
	}
	.toggle-wrap input { display: none; }
	.toggle-track {
		width: 36px; height: 20px;
		background: var(--border);
		border-radius: 0;
		position: relative;
		transition: background 0.2s;
	}
	.toggle-wrap input:checked + .toggle-track { background: var(--accent-green); }
	.toggle-thumb {
		position: absolute;
		top: 2px; left: 2px;
		width: 16px; height: 16px;
		background: var(--text-primary);
		border-radius: 50%;
		transition: left 0.2s;
	}
	.toggle-wrap input:checked + .toggle-track .toggle-thumb { left: 18px; }
	.toggle-label { font-size: 13px; font-family: monospace; color: var(--text-secondary); }

	.locked-badge {
		font-size: 12px;
		color: var(--text-muted);
		background: var(--bg-card-hover);
		border: 1px solid var(--border);
		border-radius: 0;
		padding: 6px 10px;
		display: inline-flex;
		align-items: center;
		gap: 6px;
	}
	.locked-badge code { color: var(--accent-yellow); font-size: 11px; }

	.unlock-row { display: flex; align-items: center; gap: 8px; }
	.unlock-input {
		background: var(--bg-card-hover);
		border: 1px solid var(--border);
		border-radius: 0;
		padding: 6px 10px;
		color: var(--text-secondary);
		font-size: 12px;
		font-family: monospace;
		outline: none;
		width: 200px;
	}
	.unlock-input:focus { border-color: var(--accent-cyan); }
	.unlocked-label { font-size: 12px; color: var(--accent-green); font-weight: 600; }

	.apply-fm-btn {
		align-self: flex-start;
		background: var(--accent-cyan-dim);
		border: 1px solid var(--accent-cyan-dim);
		border-radius: 0;
		padding: 8px 18px;
		color: var(--accent-cyan);
		font-weight: 600;
		font-size: 13px;
		cursor: pointer;
		transition: all 0.15s;
	}
	.apply-fm-btn:hover { background: var(--accent-cyan-dim); border-color: var(--accent-cyan); }

	/* ── Content / Toolbar ────────────────────────────────────────────────────────── */
	.toolbar {
		display: flex;
		align-items: center;
		gap: 2px;
		padding: 5px 10px;
		background: var(--bg-card);
		border-bottom: 1px solid var(--border);
		flex-shrink: 0;
		flex-wrap: wrap;
	}

	.tool-btn {
		background: none;
		border: 1px solid transparent;
		border-radius: 0;
		padding: 3px 8px;
		color: var(--text-secondary);
		font-size: 12px;
		cursor: pointer;
		transition: all 0.12s;
		white-space: nowrap;
		height: 26px;
		display: flex;
		align-items: center;
		gap: 4px;
	}
	.tool-btn:hover { color: var(--text-body); background: var(--bg-card-hover); border-color: var(--border); }

	.tool-sep { width: 1px; height: 16px; background: var(--border); margin: 0 3px; }

	.upload-lbl { cursor: pointer; }
	.hidden-file { display: none; }
	.mini-spin {
		width: 12px; height: 12px;
		border: 2px solid var(--text-muted);
		border-top-color: var(--accent-cyan);
		border-radius: 50%;
		animation: spin 0.6s linear infinite;
		display: inline-block;
	}

	/* ── Content pane ─────────────────────────────────────────────────────────────── */
	.content-pane {
		flex: 1;
		display: flex;
		overflow: hidden;
	}

	.textarea-wrap {
		flex: 1;
		display: flex;
		width: 100%;
	}
	.textarea-wrap.half { flex: 1; border-right: 1px solid var(--border-subtle); }

	.md-textarea {
		flex: 1;
		background: var(--bg-secondary);
		color: var(--text-body);
		font-family: 'JetBrains Mono', 'Fira Code', monospace;
		font-size: 14px;
		line-height: 1.8;
		padding: 20px 24px;
		border: none;
		outline: none;
		resize: none;
		width: 100%;
		height: 100%;
	}
	.md-textarea::placeholder { color: var(--text-muted); }

	.preview-pane {
		flex: 1;
		overflow-y: auto;
		background: var(--bg-secondary);
	}

	.preview-inner {
		padding: 28px 32px;
		max-width: 720px;
		color: var(--text-body);
		line-height: 1.8;
	}

	/* prose overrides for preview */
	.preview-inner :global(h1), .preview-inner :global(h2), .preview-inner :global(h3) {
		color: var(--text-primary);
		font-family: var(--font-sans);
		margin-top: 2rem;
		margin-bottom: 0.6rem;
	}
	.preview-inner :global(h1) { font-size: 1.8rem; }
	.preview-inner :global(h2) { font-size: 1.35rem; border-bottom: 1px solid var(--border-subtle); padding-bottom: 4px; }
	.preview-inner :global(h3) { font-size: 1.1rem; }
	.preview-inner :global(p) { margin-bottom: 1rem; }
	.preview-inner :global(a) { color: var(--accent-cyan); text-decoration: underline; }
	.preview-inner :global(code) { background: var(--border); padding: 2px 6px; border-radius: 0; font-size: 0.87em; color: var(--accent-green); }
	.preview-inner :global(pre) { background: var(--bg-card-hover); padding: 1rem 1.25rem; border-radius: 0; overflow-x: auto; margin: 1.5rem 0; }
	.preview-inner :global(pre code) { background: none; padding: 0; color: var(--text-body); }
	.preview-inner :global(blockquote) { border-left: 3px solid var(--border); padding-left: 1rem; color: var(--text-secondary); margin: 1rem 0; font-style: italic; }
	.preview-inner :global(ul), .preview-inner :global(ol) { padding-left: 1.5rem; margin-bottom: 1rem; }
	.preview-inner :global(li) { margin-bottom: 0.35rem; }
	.preview-inner :global(img) { max-width: 100%; border-radius: 0; margin: 1.25rem 0; display: block; }
	.preview-inner :global(table) { border-collapse: collapse; width: 100%; margin: 1.5rem 0; }
	.preview-inner :global(th) { background: var(--border); padding: 6px 12px; border-bottom: 1px solid var(--border); text-align: left; }
	.preview-inner :global(td) { padding: 6px 12px; border-bottom: 1px solid var(--border); }
	.preview-inner :global(hr) { border: none; border-top: 1px solid var(--border-subtle); margin: 2rem 0; }

	/* ── Bottom bar ──────────────────────────────────────────────────────────────── */
	.bottom-bar {
		display: flex;
		align-items: center;
		gap: 16px;
		padding: 5px 16px;
		background: var(--bg);
		border-top: 1px solid var(--bg-card-hover);
		font-size: 11px;
		color: var(--text-muted);
		flex-shrink: 0;
	}
	.word-count { color: var(--text-muted); font-family: monospace; }
	.hint-text { margin-left: auto; color: var(--border); }
	.save-status-msg { font-weight: 600; }
	.save-status-msg.ok { color: var(--accent-green); }
	.save-status-msg.error { color: var(--accent-yellow); }

	/* ── Dialogs ─────────────────────────────────────────────────────────────────── */
	.dialog-backdrop {
		position: fixed;
		inset: 0;
		background: rgba(0,0,0,0.5);
		backdrop-filter: blur(4px);
		z-index: 9000;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.dialog {
		background: var(--bg-card);
		border: 1px solid var(--border);
		border-radius: 0;
		width: 100%;
		max-width: 460px;
		display: flex;
		flex-direction: column;
		box-shadow: 0 32px 64px var(--glow-cyan);
	}

	.dialog-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 16px 20px;
		border-bottom: 1px solid var(--border-subtle);
		font-weight: 700;
		font-size: 14px;
		color: var(--text-primary);
	}

	.dialog-close {
		background: none;
		border: none;
		color: var(--text-secondary);
		font-size: 16px;
		cursor: pointer;
		padding: 0;
		line-height: 1;
	}
	.dialog-close:hover { color: var(--text-body); }

	.dialog-body {
		padding: 20px;
		display: flex;
		flex-direction: column;
		gap: 10px;
	}

	.dialog-footer {
		padding: 14px 20px;
		border-top: 1px solid var(--border-subtle);
		display: flex;
		gap: 8px;
		justify-content: flex-end;
	}

	.cancel-btn {
		background: none;
		border: 1px solid var(--border);
		border-radius: 0;
		padding: 6px 16px;
		color: var(--text-secondary);
		font-size: 12.5px;
		cursor: pointer;
	}
	.cancel-btn:hover { border-color: var(--text-muted); color: var(--text-body); }

	.slug-hint { font-size: 11px; color: var(--text-muted); margin: 0; font-family: monospace; }
	.naming-reminder {
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 8px 12px;
		background: rgba(116, 215, 237, 0.05);
		border: 1px solid rgba(116, 215, 237, 0.15);
		border-radius: 0;
		color: var(--accent-cyan);
		font-size: 11.5px;
		margin: 4px 0 2px;
		line-height: 1.4;
	}
	.naming-reminder strong { color: var(--text-primary); font-weight: 700; }
	.dialog-error { color: var(--accent-yellow); font-size: 12px; margin: 0; }

	.img-preview-wrap {
		background: var(--bg-card-hover);
		border-radius: 0;
		padding: 12px;
		display: flex;
		align-items: center;
		justify-content: center;
		margin-bottom: 4px;
	}
	.img-preview { max-height: 160px; max-width: 100%; border-radius: 0; }

	.btn-group { display: flex; gap: 5px; }
	.seg-btn {
		background: var(--bg-card-hover);
		border: 1px solid var(--border);
		border-radius: 0;
		padding: 5px 12px;
		color: var(--text-secondary);
		font-size: 12px;
		cursor: pointer;
		transition: all 0.12s;
		text-transform: capitalize;
	}
	.seg-btn:hover { color: var(--text-primary); border-color: var(--text-muted); }
	.seg-btn.active { background: var(--accent-cyan-dim); border-color: var(--accent-cyan); color: var(--accent-cyan); }

	/* ── Misc ────────────────────────────────────────────────────────────────────── */
	.spinner {
		width: 28px; height: 28px;
		border: 3px solid var(--border);
		border-top-color: var(--accent-cyan);
		border-radius: 50%;
		animation: spin 0.7s linear infinite;
	}

	@keyframes spin { to { transform: rotate(360deg); } }
</style>
