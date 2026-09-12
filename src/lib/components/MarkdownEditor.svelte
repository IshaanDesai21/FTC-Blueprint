<script lang="ts">
	import { devModeState } from '$lib/stores/devMode.svelte';
	import { fade, fly } from 'svelte/transition';
	import { marked } from 'marked';
	import markedKatex from 'marked-katex-extension';
	import { browser } from '$app/environment';

	marked.use(markedKatex({ throwOnError: false }));

	function sanitize(html: string): string {
		if (!browser) return html;
		return html; // DOMPurify not needed for our own markdown
	}

	let {
		slug,
		section = 'software',
		showFab = true
	}: {
		slug: string;
		section?: 'software' | 'hardware' | 'outreach';
		showFab?: boolean;
	} = $props();

	const GITHUB_OWNER = 'idesai-dev';
	const GITHUB_REPO = 'FTC-Blueprint';

	const GITHUB_TOKEN = import.meta.env.PUBLIC_GITHUB_TOKEN || '';

	const PRESET_TAGS = [
		{ label: 'completed', color: '#7EFFA0' },
		{ label: 'coming soon', color: '#f0c040' },
		{ label: 'beginner', color: '#74D7ED' },
		{ label: 'intermediate', color: '#a78bfa' },
		{ label: 'advanced', color: '#f87171' },
		{ label: 'software', color: '#60a5fa' },
		{ label: 'hardware', color: '#fb923c' },
		{ label: 'outreach', color: '#f472b6' }
	];

	let isOpen = $state(false);
	let isOnlyTags = $state(false);
	let activeTab = $state<'editor' | 'preview'>('editor');
	let content = $state('');
	let status = $state<'idle' | 'loading' | 'saving' | 'success' | 'error'>('idle');
	let statusMsg = $state('');
	let fileSha = $state('');
	let editorEl = $state<HTMLTextAreaElement | null>(null);
	let tagSearch = $state('');
	let currentTags = $state<string[]>([]);
	let isImageUploading = $state(false);
	let tagPopoverOpen = $state(false);
	let isMobile = $state(false);
	let imageMap = new Map<string, string>();

	function shorten(text: string): string {
		const dataUrlRegex = /data:(image|model)\/[a-zA-Z+-]+;base64,[a-zA-Z0-9+/=]+/g;
		return text.replace(dataUrlRegex, (match) => {
			const existingId = Array.from(imageMap.entries()).find(([, val]) => val === match)?.[0];
			if (existingId) {
				const type = match.split(':')[1].split(';')[0];
				return `data:${type}/...#${existingId}`;
			}
			const id = Math.random().toString(36).substring(2, 9);
			imageMap.set(id, match);
			const type = match.split(':')[1].split(';')[0];
			return `data:${type}/...#${id}`;
		});
	}

	function expand(text: string): string {
		const placeholderRegex = /data:(image|model)\/\.\.\.#([a-z0-9]+)/g;
		return text.replace(placeholderRegex, (match, type, id) => {
			return imageMap.get(id) || match;
		});
	}

	// svelte-ignore state_referenced_locally
	const filePath = `src/posts/${slug}.md`;

	const filteredPresets = $derived(
		PRESET_TAGS.filter((p) => p.label.toLowerCase().includes(tagSearch.toLowerCase()))
	);

	function parseTags(raw: string): string[] {
		const match = raw.match(/tags:\s*\[([^\]]*)\]/);
		if (!match) return [];
		return match[1]
			.split(',')
			.map((t) => t.trim().replace(/['"]/g, ''))
			.filter(Boolean);
	}

	function applyTagsToContent(raw: string, tags: string[]): string {
		const line = `tags: [${tags.map((t) => `"${t}"`).join(', ')}]`;
		if (/tags:\s*\[[^\]]*\]/.test(raw)) {
			return raw.replace(/tags:\s*\[[^\]]*\]/, line);
		}
		return raw.replace(/^(---[\s\S]*?)(---)/, `$1${line}\n$2`);
	}

	function toggleTag(tag: string) {
		const exists = currentTags.some((t) => t.toLowerCase() === tag.toLowerCase());
		if (exists) {
			currentTags = currentTags.filter((t) => t.toLowerCase() !== tag.toLowerCase());
		} else {
			currentTags = [...currentTags, tag];
		}
		content = applyTagsToContent(content, currentTags);
	}

	function addCustomTag() {
		const t = tagSearch.trim();
		if (!t || currentTags.some((ct) => ct.toLowerCase() === t.toLowerCase())) {
			tagSearch = '';
			return;
		}
		currentTags = [...currentTags, t];
		content = applyTagsToContent(content, currentTags);
		tagSearch = '';
	}

	function removeTag(tag: string) {
		currentTags = currentTags.filter((t) => t !== tag);
		content = applyTagsToContent(content, currentTags);
	}

	/** IMAGE HANDLING **/
	function insertTextAtCursor(text: string) {
		if (!editorEl) { content += text; return; }
		const start = editorEl.selectionStart;
		const end = editorEl.selectionEnd;
		content = content.substring(0, start) + text + content.substring(end);
		setTimeout(() => {
			if (editorEl) {
				editorEl.selectionStart = editorEl.selectionEnd = start + text.length;
				editorEl.focus();
			}
		}, 0);
	}

	async function uploadFile(file: File) {
		if (isImageUploading) return;
		isImageUploading = true;
		statusMsg = `Uploading ${file.name}…`;
		try {
			const isModel = file.name.endsWith('.glb') || file.name.endsWith('.gltf');
			const subfolder = isModel ? 'models' : 'images';
			
			const reader = new FileReader();
			const base64Data = await new Promise<string>((resolve) => {
				reader.onload = () => resolve((reader.result as string).split(',')[1]);
				reader.readAsDataURL(file);
			});
			const safeName = file.name.replace(/[^a-z0-9.-]/gi, '_').toLowerCase();
			const uniqueName = `${Date.now()}_${safeName}`;
			let fileUrl = '';

			if (import.meta.env.DEV) {
				try {
					const r = await fetch('/api/upload-file', {
						method: 'POST',
						headers: { 'Content-Type': 'application/json' },
						body: JSON.stringify({ slug, fileName: uniqueName, base64Data })
					});
					fileUrl = (await r.json()).url || '';
				} catch (_) {}
			}

			const token = GITHUB_TOKEN;
			if (token) {
				try {
					await fetch(
						`https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/static/${subfolder}/posts/${slug}/${uniqueName}`,
						{
							method: 'PUT',
							headers: { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github.v3+json', 'Content-Type': 'application/json' },
							body: JSON.stringify({ message: `docs: upload ${isModel ? 'model' : 'image'} for ${slug}`, content: base64Data })
						}
					);
				} catch (_) {}
			}

			if (!fileUrl) fileUrl = `/${subfolder}/posts/${slug}/${uniqueName}`;
			
			
			let url = fileUrl;
			if (url.startsWith('data:')) {
				const id = Math.random().toString(36).substring(2, 9);
				imageMap.set(id, url);
				const type = url.split(':')[1].split(';')[0];
				url = `data:${type}/...#${id}`;
			}

			if (isModel) {
				insertTextAtCursor(`\n<model-viewer src="${url}" camera-controls auto-rotate shadow-intensity="1" style="width: 100%; height: 400px; background: #1a1a1a; border-radius: 0;"></model-viewer>\n`);
			} else {
				insertTextAtCursor(`\n![${file.name}](${url})\n`);
			}
			
			statusMsg = `${isModel ? 'Model' : 'Image'} uploaded ✓`;
			setTimeout(() => (statusMsg = ''), 3000);
		} catch (e) {
			statusMsg = 'Upload failed';
		} finally {
			isImageUploading = false;
		}
	}

	async function handlePaste(e: ClipboardEvent) {
		for (const item of Array.from(e.clipboardData?.items || [])) {
			if (item.type.startsWith('image/')) {
				const file = item.getAsFile();
				if (file) { e.preventDefault(); await uploadFile(file); }
			}
		}
	}

	async function handleDrop(e: DragEvent) {
		e.preventDefault();
		for (const file of Array.from(e.dataTransfer?.files || [])) {
			const isImage = file.type.startsWith('image/');
			const isModel = file.name.endsWith('.glb') || file.name.endsWith('.gltf');
			if (isImage || isModel) await uploadFile(file);
		}
	}

	function handleFileSelect(e: Event) {
		for (const file of Array.from((e.target as HTMLInputElement).files || [])) {
			uploadFile(file);
		}
	}
	/** END IMAGE HANDLING **/

	async function fetchRawContent() {
		status = 'loading';
		statusMsg = 'Loading file…';
		content = '';
		fileSha = '';

		const token = GITHUB_TOKEN;

		// Step 1: try local disk in dev (fast, always current)
		if (import.meta.env.DEV) {
			try {
				const r = await fetch(`/api/get-local?slug=${slug}`);
				if (r.ok) {
					const d = await r.json();
					imageMap.clear();
					content = shorten(d.content);
					currentTags = parseTags(content);
				}
			} catch (_) {}
		}

		// Step 2: fetch from GitHub to get SHA + content (required for saving)
		if (token) {
			try {
				const r = await fetch(
					`https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${filePath}`,
					{ headers: { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github.v3+json' } }
				);
				if (r.ok) {
					const d = await r.json();
					fileSha = d.sha;
					// Only use GitHub content if we didn't already get it locally
					if (!content) {
						// Use TextDecoder for proper UTF-8 decoding (atob only handles ASCII)
						const b64 = d.content.replace(/\n/g, '');
						const bytes = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
						imageMap.clear();
						content = shorten(new TextDecoder().decode(bytes));
						currentTags = parseTags(content);
					}
				} else {
					const err = await r.json().catch(() => ({}));
					status = 'error';
					statusMsg = `GitHub ${r.status}: ${err.message || 'Could not load file'}`;
					return;
				}
			} catch (e) {
				status = 'error';
				statusMsg = `Network error: ${e instanceof Error ? e.message : String(e)}`;
				return;
			}
		} else if (!content) {
			status = 'idle';
			statusMsg = 'No token, cannot load file.';
			return;
		}

		status = 'idle';
		statusMsg = '';
	}

	export async function open(autoOpenTags: boolean = false) {
		isMobile = browser && window.innerWidth < 768;
		isOpen = true;
		isOnlyTags = autoOpenTags;
		tagPopoverOpen = autoOpenTags;
		activeTab = 'editor';
		await fetchRawContent();
	}

	function close() {
		isOpen = false;
		isOnlyTags = false;
		tagPopoverOpen = false;
		status = 'idle';
		statusMsg = '';
		content = '';
		fileSha = '';
	}

	async function save() {
		const token = GITHUB_TOKEN;
		if (!token) { statusMsg = 'No GitHub PAT: enter it in the footer below.'; status = 'error'; return; }
		if (!content.trim() || status === 'saving') return;
		status = 'saving';
		statusMsg = 'Committing to GitHub…';
		try {
			const expanded = expand(content);
			const encoded = btoa(unescape(encodeURIComponent(expanded)));
			const res = await fetch(
				`https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${filePath}`,
				{
					method: 'PUT',
					headers: { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github.v3+json', 'Content-Type': 'application/json' },
					body: JSON.stringify({ message: `docs: update ${slug} via editor`, content: encoded, sha: fileSha })
				}
			);
			if (!res.ok) {
				const err = await res.json();
				throw new Error(err.message || `GitHub ${res.status}`);
			}
			const d = await res.json();
			fileSha = d.content.sha;

			// Trigger deploy
			try {
				await fetch(
					`https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/workflows/deploy.yml/dispatches`,
					{ method: 'POST', headers: { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github.v3+json', 'Content-Type': 'application/json' }, body: JSON.stringify({ ref: 'main' }) }
				);
			} catch (_) {}

			// Local disk update
			if (import.meta.env.DEV) {
				try {
					await fetch('/api/save-local', {
						method: 'POST',
						headers: { 'Content-Type': 'application/json' },
						body: JSON.stringify({ slug, content })
					});
				} catch (_) {}
			}

			status = 'success';
			statusMsg = 'Saved & deploying… live in ~60s';
			setTimeout(() => { if (status === 'success') { status = 'idle'; statusMsg = ''; } }, 7000);
		} catch (e: unknown) {
			status = 'error';
			statusMsg = e instanceof Error ? e.message : 'Unknown error';
		}
	}

	function handleKeydown(e: KeyboardEvent) {
		if ((e.metaKey || e.ctrlKey) && e.key === 's') { e.preventDefault(); save(); }
		if (e.key === 'Escape') {
			if (tagPopoverOpen) tagPopoverOpen = false;
			else close();
		}
		if (e.key === 'Tab') {
			e.preventDefault();
			const el = e.target as HTMLTextAreaElement;
			const start = el.selectionStart;
			const end = el.selectionEnd;
			content = content.substring(0, start) + '  ' + content.substring(end);
			setTimeout(() => { el.selectionStart = el.selectionEnd = start + 2; }, 0);
		}
	}
</script>

{#if devModeState.active}
	{#if showFab}
		<button class="edit-fab" onclick={() => open(false)} aria-label="Edit this page">
			<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
				<path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
				<path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
			</svg>
			Edit Page
		</button>
	{/if}

	{#if isOpen}
		<div 
			class="editor-overlay" 
			transition:fade={{ duration: 150 }} 
			onclick={(e) => { if (e.target === e.currentTarget) close(); }}
			role="button"
			tabindex="-1"
			onkeydown={(e) => { if (e.key === 'Escape') close(); }}
		>
			{#if isOnlyTags}
				<div class="tag-modal" transition:fly={{ y: 20, duration: 250 }}>
					<div class="tag-modal-header">
						<div class="tag-modal-title">
							<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--accent-cyan)" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
								<path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z" /><line x1="7" y1="7" x2="7.01" y2="7" />
							</svg>
							Update Tags
						</div>
						<button class="close-btn" onclick={close}>✕</button>
					</div>

					<div class="tag-modal-body">
						<div class="current-tags-grid">
							{#each currentTags as tag}
								<span class="tag-chip">
									{tag}
									<button class="tag-chip-x" onclick={() => removeTag(tag)}>×</button>
								</span>
							{/each}
						</div>

						<div class="tag-input-wrapper">
							<input
								class="tag-modal-input"
								bind:value={tagSearch}
								placeholder="Add a custom tag..."
								onkeydown={(e) => e.key === 'Enter' && addCustomTag()}
							/>
							<button class="tag-modal-add-btn" onclick={addCustomTag}>Add</button>
						</div>

						<div class="presets-label">Quick Select</div>
						<div class="tag-modal-presets">
							{#each filteredPresets as preset}
								<button
									class="preset-tag-btn"
									class:active={currentTags.some(t => t.toLowerCase() === preset.label.toLowerCase())}
									style="--tc: {preset.color}"
									onclick={() => toggleTag(preset.label)}
								>{preset.label}</button>
							{/each}
						</div>
					</div>

					<div class="tag-modal-footer">
						{#if statusMsg}<span class="status-msg {status}">{statusMsg}</span>{/if}
						<div class="footer-actions">
							<button class="cancel-btn" onclick={close}>Cancel</button>
							<button class="save-tags-btn" onclick={save} disabled={status === 'saving' || status === 'loading'}>
								{status === 'saving' ? 'Saving...' : 'Save Changes'}
							</button>
						</div>
					</div>
				</div>
			{:else}
				<div class="editor-panel" transition:fly={{ y: 40, duration: 250 }}>
					<!-- Mobile warning banner -->
					{#if isMobile}
						<div class="mobile-warning">
							Editor not recommended on mobile, some features may not work correctly.
						</div>
					{/if}

					<!-- Header -->
					<div class="editor-header">
						<div class="editor-title">
							<span class="editor-badge">DEV</span>
							<span class="editor-filename">{filePath}</span>
						</div>

						<!-- Tags inline -->
						<div class="tags-inline">
							{#each currentTags as tag}
								<span class="tag-chip-sm">
									{tag}
									<button class="tag-chip-x" onclick={() => removeTag(tag)} aria-label="Remove {tag}">×</button>
								</span>
							{/each}
							<div class="tag-popover-wrap">
								<button class="tag-add-circle" onclick={() => (tagPopoverOpen = !tagPopoverOpen)} title="Add tag">+</button>
								{#if tagPopoverOpen}
									<div class="tag-popover" transition:fade={{ duration: 100 }}>
										<div class="tag-popover-search-row">
											<!-- svelte-ignore a11y_autofocus -->
											<input
												class="tag-popover-input"
												bind:value={tagSearch}
												placeholder="Search or add…"
												autofocus
												onkeydown={(e) => {
													if (e.key === 'Enter') addCustomTag();
													if (e.key === 'Escape') tagPopoverOpen = false;
												}}
											/>
											<button class="tag-popover-add" onclick={addCustomTag}>Add</button>
										</div>
										<div class="tag-popover-presets">
											{#each filteredPresets as preset}
												<button
													class="preset-tag-sm"
													class:active={currentTags.some(t => t.toLowerCase() === preset.label.toLowerCase())}
													style="--tc: {preset.color}"
													onclick={() => toggleTag(preset.label)}
												>{preset.label}</button>
											{/each}
										</div>
									</div>
								{/if}
							</div>
						</div>

						<!-- Right controls -->
						<div class="header-right">
							<div class="tab-row">
								<button class="tab-btn" class:active={activeTab === 'editor'} onclick={() => activeTab = 'editor'}>Editor</button>
								<button class="tab-btn" class:active={activeTab === 'preview'} onclick={() => activeTab = 'preview'}>Preview</button>
								<label class="tab-btn upload-label">
									Upload File
									<input type="file" accept="image/*, .glb, .gltf" class="hidden" onchange={handleFileSelect} />
								</label>
							</div>
							<div class="editor-actions">
								{#if statusMsg}<span class="status-msg {status}">{statusMsg}</span>{/if}
								<button class="save-btn" onclick={save} disabled={status === 'saving' || status === 'loading'}>
									Save &amp; Deploy <kbd>⌘S</kbd>
								</button>
								<button class="close-btn" onclick={close} aria-label="Close editor">✕</button>
							</div>
						</div>
					</div>

					<!-- Body -->
					<div class="editor-body">
						{#if status === 'loading'}
							<div class="editor-loading"><span class="spinner large"></span><p>Loading file…</p></div>
						{:else if status === 'error' && !content}
							<div class="editor-error">
								<p>{statusMsg}</p>
								<button class="retry-btn" onclick={fetchRawContent}>Retry</button>
							</div>
						{:else if activeTab === 'editor'}
							<div class="textarea-container">
								<textarea
									class="editor-textarea"
									bind:this={editorEl}
									bind:value={content}
									onkeydown={handleKeydown}
									onpaste={handlePaste}
									ondrop={handleDrop}
									ondragover={(e) => e.preventDefault()}
									spellcheck={false}
									placeholder="Write markdown… paste or drop images directly"
								></textarea>
								{#if isImageUploading}
									<div class="upload-overlay" transition:fade>
										<span class="spinner large"></span>
										<p>Uploading file…</p>
									</div>
								{/if}
							</div>
						{:else}
							<div class="preview-container">
								<div class="markdown-body">
									{@html sanitize(marked.parse(
										expand(content).replace(/\/images\/posts\//g,
											`https://raw.githubusercontent.com/${GITHUB_OWNER}/${GITHUB_REPO}/main/static/images/posts/`)
									) as string)}
								</div>
							</div>
						{/if}
					</div>

					<!-- Footer -->
					<div class="editor-footer">
						<span>Markdown · Paste/drop images · Esc closes</span>
						<span class="footer-right">
							<span class="pat-set">Embedded token active ✓</span>
							<span>Repo: <code>{GITHUB_OWNER}/{GITHUB_REPO}</code></span>
						</span>
					</div>
				</div>
			{/if}
		</div>
	{/if}
{/if}

<style>
	.edit-fab {
		position: fixed; bottom: 1.5rem; left: 50%; transform: translateX(-50%);
		display: flex; align-items: center; gap: 0.5rem;
		background: var(--bg-card); border: 1px solid var(--border); border-radius: 0;
		padding: 0.55rem 1.25rem; color: var(--text-secondary);
		font-family: var(--font-sans); font-size: 0.82rem; font-weight: 500;
		cursor: pointer; z-index: 900; box-shadow: 0 4px 16px rgba(0,0,0,0.25);
		transition: all 0.2s ease;
	}
	.edit-fab:hover {
		background: var(--bg-card-hover); border-color: var(--accent-cyan); color: var(--text-primary);
		box-shadow: 0 6px 20px rgba(0,0,0,0.3); transform: translateX(-50%) translateY(-2px);
	}

	.editor-overlay {
		position: fixed; inset: 0; background: rgba(0,0,0,0.82); backdrop-filter: blur(4px);
		z-index: 2000; display: flex; align-items: center; justify-content: center; padding: 1.5rem;
	}
	.editor-panel {
		width: 100%; max-width: 1200px; height: 87vh;
		background: var(--bg-secondary); border: 1px solid var(--border);
		border-radius: var(--radius-lg); display: flex; flex-direction: column;
		overflow: hidden; box-shadow: 0 32px 64px rgba(0,0,0,0.5);
	}

	/* Tag Modal Specific */
	.tag-modal {
		width: 100%; max-width: 440px; background: var(--bg-secondary); border: 1px solid var(--border);
		border-radius: var(--radius-lg); display: flex; flex-direction: column; overflow: hidden;
		box-shadow: 0 32px 64px rgba(0,0,0,0.6);
	}
	.tag-modal-header {
		display: flex; align-items: center; justify-content: space-between;
		padding: 1.25rem 1.5rem; border-bottom: 1px solid var(--border); background: var(--bg-card);
	}
	.tag-modal-title {
		display: flex; align-items: center; gap: 0.75rem; font-weight: 700; font-size: 1.1rem; color: var(--text-primary);
	}
	.tag-modal-body { padding: 1.5rem; display: flex; flex-direction: column; gap: 1.5rem; }
	.current-tags-grid { display: flex; flex-wrap: wrap; gap: 0.5rem; }
	.tag-chip {
		display: flex; align-items: center; gap: 0.4rem;
		background: rgba(116, 215, 237, 0.1); border: 1px solid var(--accent-cyan);
		color: var(--accent-cyan); padding: 0.3rem 0.75rem; border-radius: 0; font-size: 0.82rem;
	}
	.tag-chip-x {
		background: none; border: none; color: inherit; cursor: pointer;
		font-size: 0.85rem; padding: 0; line-height: 1; opacity: 0.65;
	}
	.tag-chip-x:hover { opacity: 1; }

	.tag-input-wrapper { display: flex; gap: 0.5rem; }
	.tag-modal-input {
		flex: 1; background: var(--bg-card); border: 1px solid var(--border);
		border-radius: 0; padding: 0.65rem 0.85rem; color: var(--text-primary); font-size: 0.9rem; outline: none;
	}
	.tag-modal-input:focus { border-color: var(--accent-cyan); }
	.tag-modal-add-btn {
		background: var(--bg-card); border: 1px solid var(--border); border-radius: 0;
		padding: 0 1rem; color: var(--text-primary); font-weight: 600; font-size: 0.85rem; cursor: pointer;
	}
	.presets-label { font-size: 0.72rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; color: var(--text-muted); margin-bottom: -0.75rem; }
	.tag-modal-presets { display: flex; flex-wrap: wrap; gap: 0.5rem; }
	.preset-tag-btn {
		background: var(--bg-card); border: 1px solid var(--border); padding: 0.4rem 0.85rem;
		border-radius: 0; font-size: 0.78rem; color: var(--text-secondary); cursor: pointer; transition: all 0.2s;
	}
	.preset-tag-btn:hover { border-color: var(--tc); color: var(--tc); transform: translateY(-1px); }
	.preset-tag-btn.active { border-color: var(--tc); background: var(--tc); color: #000; font-weight: 600; }

	.tag-modal-footer {
		padding: 1.25rem 1.5rem; background: var(--bg-card); border-top: 1px solid var(--border);
		display: flex; flex-direction: column; gap: 1rem;
	}
	.footer-actions { display: flex; gap: 0.75rem; justify-content: flex-end; }
	.cancel-btn { background: none; border: 1px solid var(--border); border-radius: 0; padding: 0.55rem 1.25rem; font-size: 0.85rem; color: var(--text-secondary); cursor: pointer; }
	.save-tags-btn {
		background: var(--accent-green); color: #000; border: none; border-radius: 0;
		padding: 0.55rem 1.5rem; font-weight: 700; font-size: 0.85rem; cursor: pointer;
	}
	.save-tags-btn:disabled { opacity: 0.5; cursor: not-allowed; }

	/* Mobile warning */
	.mobile-warning {
		background: rgba(248,113,113,0.12); border-bottom: 1px solid rgba(248,113,113,0.3);
		color: #f87171; font-size: 0.8rem; padding: 0.5rem 1rem; text-align: center;
	}

	/* Header */
	.editor-header {
		display: flex; align-items: center; padding: 0.6rem 1rem;
		background: var(--bg-card); border-bottom: 1px solid var(--border);
		gap: 0.75rem; min-height: 52px;
	}
	.editor-title { display: flex; align-items: center; gap: 0.5rem; flex-shrink: 0; }
	.editor-badge {
		background: var(--accent-cyan); color: #000;
		font-family: var(--font-mono); font-size: 0.62rem; font-weight: 700;
		padding: 0.15rem 0.45rem; border-radius: 0;
	}
	.editor-filename {
		font-family: var(--font-mono); font-size: 0.73rem; color: var(--text-muted);
		white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 200px;
	}

	/* Tags inline */
	.tags-inline { display: flex; align-items: center; gap: 0.35rem; flex: 1; flex-wrap: wrap; }
	.tag-chip-sm {
		display: flex; align-items: center; gap: 0.2rem;
		background: rgba(126,255,160,0.07); border: 1px solid var(--accent-green);
		color: var(--accent-green); padding: 0.12rem 0.5rem; border-radius: 0;
		font-size: 0.73rem; white-space: nowrap;
	}
	
	.tag-popover-wrap { position: relative; }
	.tag-add-circle {
		width: 20px; height: 20px; border-radius: 50%;
		border: 1.5px solid var(--border); background: none;
		color: var(--text-muted); font-size: 0.95rem; line-height: 1;
		cursor: pointer; display: flex; align-items: center; justify-content: center;
		transition: all 0.15s;
	}
	.tag-add-circle:hover { border-color: var(--accent-cyan); color: var(--accent-cyan); background: rgba(125,225,255,0.07); }

	.tag-popover {
		position: absolute; top: calc(100% + 6px); left: 0; z-index: 3000;
		background: var(--bg-card); border: 1px solid var(--border); border-radius: 0;
		padding: 0.75rem; min-width: 260px; max-width: 320px;
		box-shadow: 0 8px 24px rgba(0,0,0,0.45); display: flex; flex-direction: column; gap: 0.55rem;
	}
	.tag-popover-search-row { display: flex; gap: 0.4rem; }
	.tag-popover-input {
		flex: 1; background: var(--bg-secondary); border: 1px solid var(--border);
		border-radius: 0; padding: 0.38rem 0.65rem; color: var(--text-primary);
		font-size: 0.82rem; outline: none;
	}
	.tag-popover-input:focus { border-color: var(--accent-cyan); }
	.tag-popover-add {
		background: var(--accent-cyan); border: none; border-radius: 0;
		padding: 0.38rem 0.8rem; font-weight: 700; font-size: 0.78rem;
		cursor: pointer; color: #000; white-space: nowrap;
	}
	.tag-popover-presets { display: flex; flex-wrap: wrap; gap: 0.35rem; }
	.preset-tag-sm {
		background: none; border: 1px solid var(--border); padding: 0.18rem 0.65rem;
		border-radius: 0; font-size: 0.74rem; color: var(--text-muted); cursor: pointer; transition: all 0.15s;
	}
	.preset-tag-sm:hover { border-color: var(--tc); color: var(--tc); }
	.preset-tag-sm.active { border-color: var(--tc); background: var(--tc); color: #000; }

	/* Right side */
	.header-right { display: flex; align-items: center; gap: 0.6rem; flex-shrink: 0; margin-left: auto; }
	.tab-row { display: flex; gap: 0.35rem; }
	.tab-btn {
		background: none; border: 1px solid transparent; border-radius: 0;
		padding: 0.32rem 0.65rem; font-size: 0.77rem; color: var(--text-muted);
		cursor: pointer; transition: all 0.2s; white-space: nowrap;
	}
	.tab-btn:hover { color: var(--text-primary); background: rgba(255,255,255,0.05); }
	.tab-btn.active { color: var(--text-primary); background: var(--bg-secondary); border-color: var(--border); }
	.upload-label { cursor: pointer; }
	.hidden { display: none; }

	.editor-actions { display: flex; align-items: center; gap: 0.6rem; }
	.save-btn {
		background: var(--accent-green); color: #111; border: none; border-radius: 0;
		padding: 0.42rem 1rem; font-weight: 700; font-size: 0.79rem; cursor: pointer;
		display: flex; gap: 0.35rem; align-items: center; white-space: nowrap;
	}
	.save-btn:disabled { opacity: 0.45; cursor: not-allowed; }
	.close-btn { background: none; border: none; color: var(--text-muted); font-size: 1.15rem; cursor: pointer; }

	/* Body */
	.editor-body { flex: 1; overflow: hidden; display: flex; flex-direction: column; }
	.editor-loading { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 1rem; color: var(--text-muted); font-size: 0.9rem; }
	.editor-error { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 0.75rem; color: #f87171; font-size: 0.9rem; text-align: center; padding: 2rem; }
	.retry-btn { background: var(--bg-card); border: 1px solid var(--border); border-radius: 0; padding: 0.4rem 1rem; color: var(--text-primary); cursor: pointer; font-size: 0.82rem; }

	.textarea-container { flex: 1; position: relative; display: flex; }
	.editor-textarea {
		flex: 1; background: var(--bg-secondary); color: var(--text-primary);
		font-family: var(--font-mono); font-size: 0.96rem; padding: 1.75rem 2rem;
		border: none; outline: none; resize: none; line-height: 1.8;
	}
	.editor-textarea::placeholder { color: var(--text-muted); opacity: 0.5; }

	.preview-container {
		flex: 1; background: var(--bg-secondary); color: var(--text-primary);
		padding: 2rem 2.5rem; overflow-y: auto; line-height: 1.7; font-family: var(--font-sans);
	}

	.upload-overlay {
		position: absolute; inset: 0; background: rgba(0,0,0,0.7);
		display: flex; flex-direction: column; align-items: center; justify-content: center;
		gap: 1rem; color: var(--accent-cyan); z-index: 10;
	}

	.spinner {
		width: 1.4rem; height: 1.4rem; border: 2.5px solid currentColor;
		border-top-color: transparent; border-radius: 50%;
		animation: spin 0.7s linear infinite; display: inline-block;
	}
	.spinner.large { width: 2.5rem; height: 2.5rem; }
	@keyframes spin { to { transform: rotate(360deg); } }

	/* Footer */
	.editor-footer {
		padding: 0.45rem 1rem; background: var(--bg-card); border-top: 1px solid var(--border);
		display: flex; justify-content: space-between; align-items: center;
		font-family: var(--font-mono); font-size: 0.68rem; color: var(--text-muted); gap: 1rem;
	}
	.footer-right { display: flex; align-items: center; gap: 0.5rem; }
	.pat-set { color: var(--accent-green); }

	.status-msg { font-size: 0.78rem; max-width: 320px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
	.status-msg.error { color: #f87171; }
	.status-msg.success { color: var(--accent-green); }
</style>

<!-- Preview styles injected globally since {@html} creates elements outside Svelte scope -->
<svelte:head>
	<style>
		.preview-container .markdown-body h1 { font-size: 1.9rem; font-weight: 800; margin-bottom: 1.25rem; }
		.preview-container .markdown-body h2 { font-size: 1.45rem; font-weight: 700; margin-top: 2rem; margin-bottom: 0.9rem; border-bottom: 1px solid rgba(255,255,255,0.1); padding-bottom: 0.5rem; }
		.preview-container .markdown-body h3 { font-size: 1.1rem; font-weight: 600; margin-top: 1.5rem; margin-bottom: 0.6rem; }
		.preview-container .markdown-body p { margin-bottom: 1rem; opacity: 0.85; }
		.preview-container .markdown-body a { color: #7de0ff; text-decoration: underline; }
		.preview-container .markdown-body ul, .preview-container .markdown-body ol { padding-left: 1.5rem; margin-bottom: 1rem; opacity: 0.85; }
		.preview-container .markdown-body li { margin-bottom: 0.3rem; }
		.preview-container .markdown-body img { max-width: 100%; border-radius: 0; margin: 1.5rem 0; display: block; box-shadow: 0 4px 12px rgba(0,0,0,0.3); }
		.preview-container .markdown-body pre { background: #111; padding: 1rem; border-radius: 0; overflow-x: auto; margin: 1.5rem 0; font-size: 0.88rem; }
		.preview-container .markdown-body code { background: rgba(255,255,255,0.08); padding: 0.15rem 0.4rem; border-radius: 0; font-size: 0.87em; }
		.preview-container .markdown-body blockquote { border-left: 3px solid #7de0ff; padding-left: 1rem; opacity: 0.75; margin: 1rem 0; }
		.preview-container .markdown-body hr { border: none; border-top: 1px solid rgba(255,255,255,0.1); margin: 2rem 0; }
		.preview-container .markdown-body table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
		.preview-container .markdown-body th { background: rgba(255,255,255,0.05); padding: 0.5rem 0.8rem; text-align: left; border-bottom: 1px solid rgba(255,255,255,0.1); }
		.preview-container .markdown-body td { padding: 0.45rem 0.8rem; border-bottom: 1px solid rgba(255,255,255,0.05); }
	</style>
</svelte:head>
