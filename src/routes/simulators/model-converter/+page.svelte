<script lang="ts">
	import { onDestroy } from 'svelte';
	import * as THREE from 'three';
	import { STLLoader } from 'three/addons/loaders/STLLoader.js';
	import { OBJLoader } from 'three/addons/loaders/OBJLoader.js';
	import { PLYLoader } from 'three/addons/loaders/PLYLoader.js';
	import { FBXLoader } from 'three/addons/loaders/FBXLoader.js';
	import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
	import { ColladaLoader } from 'three/addons/loaders/ColladaLoader.js';
	import { ThreeMFLoader } from 'three/addons/loaders/3MFLoader.js';
	import { GLTFExporter } from 'three/addons/exporters/GLTFExporter.js';
	import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
	import { fade, fly } from 'svelte/transition';

	let canvas = $state<HTMLCanvasElement | null>(null);
	let viewerWrap = $state<HTMLDivElement | null>(null);
	let fileInput = $state<HTMLInputElement | null>(null);

	let renderer: THREE.WebGLRenderer;
	let scene = new THREE.Scene();
	let camera: THREE.PerspectiveCamera;
	let controls: OrbitControls;
	let animFrame: number;
	let currentObject = $state<THREE.Object3D | null>(null);
	let currentFile = $state<File | null>(null);

	let showViewer = $state(false);
	let showStats = $state(false);
	let showButtons = $state(false);
	let converting = $state(false);
	let dragging = $state(false);
	let status = $state('');
	let statusHint = $state('');
	let lastDownload = $state('');

	let stats = $state({ verts: 0, tris: 0, size: 0, fmt: '' });

	const FORMATS = [
		{ ext: 'stl',  label: 'STL',     cat: 'mesh' },
		{ ext: 'obj',  label: 'OBJ',     cat: 'mesh' },
		{ ext: 'ply',  label: 'PLY',     cat: 'mesh' },
		{ ext: 'fbx',  label: 'FBX',     cat: 'mesh' },
		{ ext: 'glb',  label: 'GLB',     cat: 'mesh' },
		{ ext: 'gltf', label: 'GLTF',    cat: 'mesh' },
		{ ext: 'dae',  label: 'Collada', cat: 'mesh' },
		{ ext: '3mf',  label: '3MF',     cat: 'mesh' },
		{ ext: 'step', label: 'STEP',    cat: 'cad'  },
		{ ext: 'stp',  label: 'STP',     cat: 'cad'  },
	];
	const SUPPORTED_EXTS = FORMATS.map(f => f.ext);
	const ACCEPT_ATTR = SUPPORTED_EXTS.map(e => '.' + e).join(',');

	// ── OCCT loader (lazy, cached) ──────────────────────────────────────────────
	let occtCache: any = null;

	async function loadOCCT(): Promise<any> {
		if (occtCache) return occtCache;
		statusHint = 'Downloading CAD kernel (one-time, ~8 MB)…';

		await new Promise<void>((res, rej) => {
			if ((window as any).occtimportjs) { res(); return; }
			const s = document.createElement('script');
			s.src = 'https://cdn.jsdelivr.net/npm/occt-import-js@0.0.22/dist/occt-import-js.js';
			s.onload = () => res();
			s.onerror = () => rej(new Error('Failed to load occt-import-js from CDN'));
			document.head.appendChild(s);
		});

		statusHint = 'Initialising CAD kernel…';
		occtCache = await (window as any).occtimportjs({
			locateFile: (f: string) =>
				`https://cdn.jsdelivr.net/npm/occt-import-js@0.0.22/dist/${f}`,
		});
		statusHint = '';
		return occtCache;
	}

	// ── Three.js init ───────────────────────────────────────────────────────────
	function initRenderer() {
		if (renderer || !canvas || !viewerWrap) return;

		renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
		renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
		renderer.setSize(viewerWrap.clientWidth, 400, false);
		renderer.shadowMap.enabled = true;

		camera = new THREE.PerspectiveCamera(50, viewerWrap.clientWidth / 400, 0.1, 1000);
		camera.position.set(3, 2, 3);

		scene.add(new THREE.AmbientLight(0xffffff, 0.5));

		const main = new THREE.DirectionalLight(0xffffff, 1);
		main.position.set(5, 10, 7);
		main.castShadow = true;
		scene.add(main);

		const fill = new THREE.PointLight(0x7de0ff, 0.5);
		fill.position.set(-5, 5, -5);
		scene.add(fill);

		scene.add(new THREE.GridHelper(10, 20, 0x444444, 0x222222));

		controls = new OrbitControls(camera, canvas);
		controls.enableDamping = true;
		controls.dampingFactor = 0.1;

		const ro = new ResizeObserver(() => {
			if (!viewerWrap || !renderer) return;
			const w = viewerWrap.clientWidth;
			renderer.setSize(w, 400, false);
			camera.aspect = w / 400;
			camera.updateProjectionMatrix();
		});
		ro.observe(viewerWrap);

		(function animate() {
			animFrame = requestAnimationFrame(animate);
			controls.update();
			renderer.render(scene, camera);
		})();
	}

	// ── Helpers ─────────────────────────────────────────────────────────────────
	function applyDefaultMaterial(obj: THREE.Object3D) {
		obj.traverse((c: THREE.Object3D) => {
			if (c instanceof THREE.Mesh) {
				c.castShadow = true;
				if (!c.material || (c.material as any).type === 'MeshBasicMaterial') {
					c.material = new THREE.MeshStandardMaterial({
						color: 0x7de0ff, roughness: 0.3, metalness: 0.8, side: THREE.DoubleSide,
					});
				}
			}
		});
	}

	function fitAndPlace(obj: THREE.Object3D) {
		if (currentObject) scene.remove(currentObject);
		scene.add(obj);

		const box = new THREE.Box3().setFromObject(obj);
		const size = new THREE.Vector3();
		const center = new THREE.Vector3();
		box.getSize(size);
		box.getCenter(center);

		const scale = 2 / (Math.max(size.x, size.y, size.z) || 1);
		obj.scale.multiplyScalar(scale);
		obj.position.sub(center.multiplyScalar(scale));

		currentObject = obj;
		camera.position.set(2, 1.5, 2);
		controls.target.set(0, 0, 0);
	}

	function placeMesh(geometry: THREE.BufferGeometry) {
		geometry.computeVertexNormals();
		geometry.center();
		const mesh = new THREE.Mesh(geometry, new THREE.MeshStandardMaterial({
			color: 0x7de0ff, roughness: 0.3, metalness: 0.8, side: THREE.DoubleSide,
		}));
		mesh.castShadow = true;
		fitAndPlace(mesh);
	}

	function countGeomStats(root: THREE.Object3D) {
		let v = 0, t = 0;
		root.traverse((c: THREE.Object3D) => {
			if (c instanceof THREE.Mesh) {
				const p = c.geometry?.attributes?.position;
				if (p) {
					v += p.count;
					t += c.geometry.index
						? c.geometry.index.count / 3
						: Math.floor(p.count / 3);
				}
			}
		});
		return { verts: v, tris: Math.round(t) };
	}

	// ── STEP → Three.js ─────────────────────────────────────────────────────────
	async function loadStep(buf: ArrayBuffer): Promise<THREE.Group> {
		const occt = await loadOCCT();
		statusHint = 'Tessellating CAD geometry…';
		const result = occt.ReadStepFile(new Uint8Array(buf), null);
		statusHint = '';

		if (!result?.success) throw new Error('OCCT could not parse this STEP file.');

		const group = new THREE.Group();
		for (const mesh of result.meshes ?? []) {
			const geo = new THREE.BufferGeometry();
			geo.setAttribute('position',
				new THREE.BufferAttribute(new Float32Array(mesh.attributes.position.array), 3));
			if (mesh.attributes.normal) {
				geo.setAttribute('normal',
					new THREE.BufferAttribute(new Float32Array(mesh.attributes.normal.array), 3));
			}
			if (mesh.index) {
				geo.setIndex(new THREE.BufferAttribute(new Uint32Array(mesh.index.array), 1));
			}
			geo.computeVertexNormals();

			const color = mesh.color
				? new THREE.Color(mesh.color[0], mesh.color[1], mesh.color[2])
				: new THREE.Color(0x7de0ff);
			const mat = new THREE.MeshStandardMaterial({
				color, roughness: 0.3, metalness: 0.6, side: THREE.DoubleSide,
			});
			const m = new THREE.Mesh(geo, mat);
			m.castShadow = true;
			group.add(m);
		}
		if (group.children.length === 0) throw new Error('STEP file contained no renderable geometry.');
		return group;
	}

	// ── Main file handler ───────────────────────────────────────────────────────
	async function handleFile(file: File) {
		if (!file) return;
		const ext = file.name.split('.').pop()?.toLowerCase() ?? '';
		if (!SUPPORTED_EXTS.includes(ext)) {
			status = `Unsupported format ".${ext}".`;
			statusHint = `Accepted: ${SUPPORTED_EXTS.join(', ').toUpperCase()}`;
			return;
		}

		currentFile = file;
		showViewer = true;
		showStats = false;
		showButtons = false;
		status = 'Loading model…';
		statusHint = '';
		lastDownload = '';

		setTimeout(() => {
			initRenderer();

			const reader = new FileReader();
			reader.onerror = () => { status = 'Failed to read file.'; statusHint = ''; };
			reader.onload = async (e) => {
				try {
					const buf = e.target?.result as ArrayBuffer;

					if (ext === 'stl') {
						const geo = new STLLoader().parse(buf);
						placeMesh(geo);
						const v = geo.attributes.position.count;
						stats = { verts: v, tris: Math.floor(v / 3), size: file.size, fmt: 'STL' };

					} else if (ext === 'ply') {
						const geo = new PLYLoader().parse(buf);
						placeMesh(geo);
						const v = geo.attributes.position.count;
						stats = { verts: v, tris: geo.index ? Math.round(geo.index.count / 3) : Math.floor(v / 3), size: file.size, fmt: 'PLY' };

					} else if (ext === 'obj') {
						const group = new OBJLoader().parse(new TextDecoder().decode(buf)) as THREE.Group;
						applyDefaultMaterial(group);
						fitAndPlace(group);
						stats = { ...countGeomStats(group), size: file.size, fmt: 'OBJ' };

					} else if (ext === 'fbx') {
						const group = new FBXLoader().parse(buf, '') as THREE.Group;
						applyDefaultMaterial(group);
						fitAndPlace(group);
						stats = { ...countGeomStats(group), size: file.size, fmt: 'FBX' };

					} else if (ext === 'glb' || ext === 'gltf') {
						const gltf = await new Promise<any>((res, rej) =>
							new GLTFLoader().parse(buf, '', res, rej));
						applyDefaultMaterial(gltf.scene);
						fitAndPlace(gltf.scene);
						stats = { ...countGeomStats(gltf.scene), size: file.size, fmt: ext.toUpperCase() };

					} else if (ext === 'dae') {
						const collada = new ColladaLoader().parse(new TextDecoder().decode(buf), '');
						if (!collada) throw new Error('Collada loader returned null: file may be malformed.');
						applyDefaultMaterial(collada.scene);
						fitAndPlace(collada.scene);
						stats = { ...countGeomStats(collada.scene), size: file.size, fmt: 'Collada' };

					} else if (ext === '3mf') {
						const group = await new ThreeMFLoader().parse(buf) as THREE.Group;
						applyDefaultMaterial(group);
						fitAndPlace(group);
						stats = { ...countGeomStats(group), size: file.size, fmt: '3MF' };

					} else if (ext === 'step' || ext === 'stp') {
						const group = await loadStep(buf);
						fitAndPlace(group);
						stats = { ...countGeomStats(group), size: file.size, fmt: 'STEP' };
					}

					showStats = true;
					showButtons = true;
					status = '';
					statusHint = '';
				} catch (err: any) {
					status = 'Error: ' + (err?.message ?? String(err));
					statusHint = '';
					showViewer = false;
				}
			};
			reader.readAsArrayBuffer(file);
		}, 50);
	}

	function convert() {
		if (!currentObject || !currentFile) return;
		converting = true;
		status = 'Exporting GLB…';
		new GLTFExporter().parse(
			currentObject,
			(result: any) => {
				const blob = new Blob([result as ArrayBuffer], { type: 'model/gltf-binary' });
				const url = URL.createObjectURL(blob);
				const a = Object.assign(document.createElement('a'), {
					href: url,
					download: currentFile!.name.replace(/\.[^/.]+$/, '') + '.glb',
				});
				a.click();
				URL.revokeObjectURL(url);
				lastDownload = `Downloaded ${a.download}`;
				status = '';
				converting = false;
			},
			(err: any) => { status = 'Export failed: ' + err; converting = false; },
			{ binary: true }
		);
	}

	function reset() {
		if (currentObject) { scene.remove(currentObject); currentObject = null; }
		currentFile = null;
		showViewer = false;
		showStats = false;
		showButtons = false;
		status = '';
		statusHint = '';
		lastDownload = '';
		if (fileInput) fileInput.value = '';
	}

	function fmtBytes(b: number) {
		if (b < 1024) return b + ' B';
		if (b < 1048576) return (b / 1024).toFixed(1) + ' KB';
		return (b / 1048576).toFixed(2) + ' MB';
	}

	onDestroy(() => {
		if (animFrame) cancelAnimationFrame(animFrame);
		renderer?.dispose();
	});
</script>

<svelte:head>
	<title>Model Converter | Blueprint</title>
	<meta name="description" content="Convert STL, OBJ, PLY, FBX, GLTF, Collada, 3MF, and STEP files to optimised GLB models for Blueprint." />
</svelte:head>

<section class="converter-hero">
	<div class="container">
		<div class="animate-fade-up">
			<span class="tag tag--cyan">Developer Tool</span>
		</div>
		<h1 class="animate-fade-up" style="animation-delay: 60ms">Model Converter</h1>
		<p class="hero-desc animate-fade-up" style="animation-delay: 120ms">
			Transform 3D mesh and CAD exports into lightweight GLB models for the Blueprint 3D viewer.
		</p>
	</div>
</section>

<div class="container converter-content" style="padding-bottom: 10rem;">
	<div class="card animate-fade-up" style="animation-delay: 180ms">
		{#if !showViewer}
			<!-- svelte-ignore a11y_click_events_have_key_events -->
			<!-- svelte-ignore a11y_no_noninteractive_element_to_interactive_role -->
			<div
				class="drop-zone"
				class:dragging
				role="button"
				tabindex="0"
				ondragover={(e) => { e.preventDefault(); dragging = true; }}
				ondragleave={() => dragging = false}
				ondrop={(e) => { e.preventDefault(); dragging = false; handleFile(e.dataTransfer!.files[0]); }}
				onclick={() => fileInput?.click()}
			>
				<input bind:this={fileInput} type="file" accept={ACCEPT_ATTR} class="hidden"
					onchange={(e) => handleFile((e.target as HTMLInputElement).files![0])} />

				<div class="drop-icon">
					<svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
						<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
						<polyline points="17 8 12 3 7 8"/>
						<line x1="12" y1="3" x2="12" y2="15"/>
					</svg>
				</div>

				<h3>Drop your 3D file here</h3>
				<p>or click to browse</p>

				<div class="format-groups">
					<div class="format-group">
						<span class="format-group-label">Mesh</span>
						<div class="format-chips">
							{#each FORMATS.filter(f => f.cat === 'mesh') as f}
								<span class="chip">{f.label}</span>
							{/each}
						</div>
					</div>
					<div class="format-divider"></div>
					<div class="format-group">
						<span class="format-group-label">CAD</span>
						<div class="format-chips">
							{#each FORMATS.filter(f => f.cat === 'cad') as f}
								<span class="chip chip--cad">{f.label}</span>
							{/each}
						</div>
					</div>
				</div>

				<p class="step-note">
					<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="display:inline;vertical-align:-2px;margin-right:4px"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
					STEP files load a ~8 MB CAD kernel on first use
				</p>
			</div>

		{:else}
			<div class="viewer-container" transition:fade>
				<div bind:this={viewerWrap} class="viewer-wrap">
					<canvas bind:this={canvas}></canvas>
					{#if status && !showStats}
						<div class="viewer-loading" transition:fade>
							<span class="spinner-lg"></span>
							<span class="loading-text">{status}</span>
							{#if statusHint}
								<span class="loading-hint">{statusHint}</span>
							{/if}
						</div>
					{/if}
				</div>

				{#if showStats}
					<div class="stats-grid" transition:fly={{ y: 20 }}>
						<div class="stat-card">
							<span class="label">Format</span>
							<span class="value">{stats.fmt}</span>
						</div>
						<div class="stat-card">
							<span class="label">Vertices</span>
							<span class="value">{stats.verts.toLocaleString()}</span>
						</div>
						<div class="stat-card">
							<span class="label">Faces</span>
							<span class="value">{stats.tris.toLocaleString()}</span>
						</div>
						<div class="stat-card">
							<span class="label">File Size</span>
							<span class="value">{fmtBytes(stats.size)}</span>
						</div>
					</div>
				{/if}

				{#if showButtons}
					<div class="actions-row" transition:fly={{ y: 10 }}>
						<button class="btn btn--blue full-width" onclick={convert} disabled={converting}>
							{#if converting}
								<span class="spinner"></span> Converting…
							{:else}
								<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="margin-right:6px">
									<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
									<polyline points="7 10 12 15 17 10"/>
									<line x1="12" y1="15" x2="12" y2="3"/>
								</svg>
								Export as GLB
							{/if}
						</button>
						<button class="btn btn--secondary" onclick={reset}>
							<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
								<polyline points="15 18 9 12 15 6"/>
							</svg>
							New File
						</button>
					</div>
				{/if}
			</div>
		{/if}

		{#if status && showViewer && showStats}
			<div class="status-banner" transition:fade>{status}</div>
		{/if}

		{#if status && !showViewer}
			<div class="error-banner" transition:fade>
				<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
					<circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
				</svg>
				<div>
					<span>{status}</span>
					{#if statusHint}<span class="error-hint">{statusHint}</span>{/if}
				</div>
			</div>
		{/if}

		{#if lastDownload}
			<div class="success-banner" transition:fade>
				<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
					<polyline points="20 6 9 17 4 12"/>
				</svg>
				{lastDownload}
			</div>
		{/if}
	</div>

	<div class="info-section animate-fade-up" style="animation-delay: 240ms">
		<h2>Why GLB?</h2>
		<p>
			GLB is the industry standard for 3D web graphics. It bundles geometry, textures, and lighting data
			into a single efficient binary that loads 10× faster than raw CAD formats like STEP or STL.
		</p>
		<div class="info-grid">
			<div class="info-card">
				<span class="info-card-title">STEP / STP</span>
				<span class="info-card-desc">Full CAD solids with exact B-rep geometry, tessellated client-side via OpenCASCADE WASM</span>
			</div>
			<div class="info-card">
				<span class="info-card-title">STL / OBJ / PLY</span>
				<span class="info-card-desc">Raw mesh formats from slicers and scan software, loaded instantly with no extra kernel</span>
			</div>
			<div class="info-card">
				<span class="info-card-title">FBX / GLTF / DAE</span>
				<span class="info-card-desc">Animation-ready interchange formats from DCC tools like Blender, Maya, and 3ds Max</span>
			</div>
		</div>
	</div>
</div>

<style>
	.converter-hero {
		padding: 6rem 0 4rem;
		background: var(--gradient-hero);
		border-bottom: 1px solid var(--border-subtle);
		margin-bottom: 3rem;
	}

	/* ── Card ── */
	.card {
		background: var(--bg-card);
		border: 1px solid var(--border);
		border-radius: var(--radius-lg);
		padding: 2.5rem;
		box-shadow: 0 8px 32px rgba(0,0,0,0.2);
		margin-bottom: 4rem;
	}

	/* ── Drop zone ── */
	.drop-zone {
		border: 2px dashed var(--border);
		border-radius: var(--radius-md);
		padding: 3.5rem 2rem 2.5rem;
		text-align: center;
		cursor: pointer;
		transition: all var(--transition-base);
		background: rgba(255,255,255,0.02);
		user-select: none;
	}

	.drop-zone:hover,
	.drop-zone.dragging {
		border-color: var(--accent-cyan);
		background: rgba(116, 215, 237, 0.05);
		transform: translateY(-2px);
	}

	.drop-icon {
		color: var(--accent-cyan);
		margin-bottom: 1.25rem;
		opacity: 0.8;
	}

	.drop-zone h3 { font-size: 1.4rem; margin-bottom: 0.35rem; }
	.drop-zone > p  { color: var(--text-muted); margin-bottom: 2rem; }

	/* ── Format groups ── */
	.format-groups {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 1.25rem;
		flex-wrap: wrap;
		margin-bottom: 1.25rem;
	}

	.format-group {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.5rem;
	}

	.format-group-label {
		font-size: 0.65rem;
		font-weight: 700;
		letter-spacing: 0.1em;
		text-transform: uppercase;
		color: var(--text-muted);
	}

	.format-chips { display: flex; gap: 0.4rem; flex-wrap: wrap; justify-content: center; }

	.chip {
		display: inline-block;
		padding: 0.25rem 0.6rem;
		background: var(--bg-secondary);
		border: 1px solid var(--border);
		border-radius: 0;
		font-family: var(--font-mono);
		font-size: 0.72rem;
		color: var(--text-secondary);
	}

	.chip--cad {
		border-color: rgba(116, 215, 237, 0.35);
		color: var(--accent-cyan);
		background: rgba(116, 215, 237, 0.07);
	}

	.format-divider {
		width: 1px;
		height: 40px;
		background: var(--border-subtle);
		align-self: center;
	}

	.step-note {
		font-size: 0.78rem;
		color: var(--text-muted);
		margin-top: 0.25rem;
		margin-bottom: 0 !important;
	}

	/* ── Viewer ── */
	.viewer-wrap {
		position: relative;
		width: 100%;
		height: 400px;
		background: #0a0a0a;
		border-radius: var(--radius-md);
		border: 1px solid var(--border);
		overflow: hidden;
		margin-bottom: 1.5rem;
	}

	.viewer-loading {
		position: absolute;
		inset: 0;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 0.75rem;
		background: rgba(10,10,10,0.85);
		backdrop-filter: blur(4px);
	}

	.loading-text {
		font-size: 0.95rem;
		color: var(--text-secondary);
		font-weight: 500;
	}

	.loading-hint {
		font-size: 0.78rem;
		color: var(--text-muted);
	}

	/* ── Stats ── */
	.stats-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
		gap: 0.75rem;
		margin-bottom: 1.5rem;
	}

	.stat-card {
		background: var(--bg-secondary);
		padding: 0.9rem 1rem;
		border-radius: var(--radius-md);
		border: 1px solid var(--border-subtle);
		display: flex;
		flex-direction: column;
		gap: 0.25rem;
	}

	.stat-card .label { font-size: 0.68rem; text-transform: uppercase; color: var(--text-muted); font-weight: 700; letter-spacing: 0.06em; }
	.stat-card .value { font-size: 1.05rem; font-family: var(--font-mono); font-weight: 600; color: var(--text-primary); }

	/* ── Actions ── */
	.actions-row {
		display: flex;
		gap: 0.75rem;
	}

	.full-width { flex: 1; }

	/* ── Banners ── */
	.status-banner {
		margin-top: 1.25rem;
		padding: 0.9rem 1rem;
		background: rgba(255,255,255,0.04);
		border-radius: var(--radius-md);
		font-size: 0.88rem;
		text-align: center;
		color: var(--text-secondary);
	}

	.error-banner {
		margin-top: 1.25rem;
		padding: 1rem 1.25rem;
		background: rgba(255, 100, 100, 0.08);
		border: 1px solid rgba(255, 100, 100, 0.3);
		border-radius: var(--radius-md);
		color: #ff8080;
		display: flex;
		align-items: flex-start;
		gap: 0.75rem;
		font-size: 0.9rem;
	}

	.error-hint {
		display: block;
		font-size: 0.8rem;
		opacity: 0.7;
		margin-top: 0.2rem;
	}

	.success-banner {
		margin-top: 1.25rem;
		padding: 1.1rem 1.25rem;
		background: rgba(126, 255, 160, 0.08);
		border: 1px solid var(--accent-green);
		border-radius: var(--radius-md);
		color: var(--accent-green);
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.75rem;
		font-weight: 600;
		font-size: 0.95rem;
	}

	/* ── Info section ── */
	.info-section { max-width: 680px; }
	.info-section h2 { font-size: 1.8rem; margin-bottom: 0.75rem; }
	.info-section > p  { color: var(--text-secondary); line-height: 1.7; margin-bottom: 1.5rem; }

	.info-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
		gap: 1rem;
	}

	.info-card {
		background: var(--bg-secondary);
		border: 1px solid var(--border-subtle);
		border-radius: var(--radius-md);
		padding: 1rem 1.1rem;
		display: flex;
		flex-direction: column;
		gap: 0.4rem;
	}

	.info-card-title {
		font-family: var(--font-mono);
		font-size: 0.8rem;
		font-weight: 700;
		color: var(--accent-cyan);
	}

	.info-card-desc {
		font-size: 0.82rem;
		color: var(--text-muted);
		line-height: 1.5;
	}

	/* ── Spinners ── */
	.spinner {
		display: inline-block;
		width: 13px;
		height: 13px;
		border: 2px solid rgba(255,255,255,0.35);
		border-top-color: white;
		border-radius: 50%;
		animation: spin 0.6s linear infinite;
		margin-right: 7px;
		vertical-align: -2px;
	}

	.spinner-lg {
		display: block;
		width: 32px;
		height: 32px;
		border: 3px solid rgba(116, 215, 237, 0.2);
		border-top-color: var(--accent-cyan);
		border-radius: 50%;
		animation: spin 0.8s linear infinite;
	}

	@keyframes spin { to { transform: rotate(360deg); } }

	.hidden { display: none; }

	@media (max-width: 640px) {
		.actions-row { flex-direction: column; }
		.format-divider { width: 40px; height: 1px; }
	}
</style>