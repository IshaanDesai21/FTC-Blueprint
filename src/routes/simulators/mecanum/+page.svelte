<script lang="ts">
	import { onMount } from 'svelte';

	// ── Raw key state ──────────────────────────────────────────────────────────
	let keys = $state({ w: false, a: false, s: false, d: false, q: false, e: false });
	let isFieldCentric = $state(false);
	let imuAngle = $state(0);          // degrees, updated by Q/E in both modes

	let accel = $state(0.18);

	let smooth_x = $state(0);
	let smooth_y = $state(0);
	let smooth_rx = $state(0);

	let target_y  = $derived((keys.w ? 1 : 0) + (keys.s ? -1 : 0));
	let target_x  = $derived((keys.d ? 1 : 0) + (keys.a ? -1 : 0));
	let target_rx = $derived((keys.e ? 1 : 0) + (keys.q ? -1 : 0));

	let rad = $derived((-imuAngle * Math.PI) / 180);
	let x = $derived(isFieldCentric
		? smooth_x * Math.cos(rad) - smooth_y * Math.sin(rad)
		: smooth_x);
	let y = $derived(isFieldCentric
		? smooth_x * Math.sin(rad) + smooth_y * Math.cos(rad)
		: smooth_y);
	let rx = $derived(smooth_rx);

	let fl = $derived(y + x + rx);
	let fr = $derived(y - x - rx);
	let bl = $derived(y - x + rx);
	let br = $derived(y + x - rx);

	let maxMag = $derived(Math.max(Math.abs(fl), Math.abs(fr), Math.abs(bl), Math.abs(br), 1));
	let fl_n = $derived(fl / maxMag);
	let fr_n = $derived(fr / maxMag);
	let bl_n = $derived(bl / maxMag);
	let br_n = $derived(br / maxMag);

	let arrowAngleDeg = $derived(
		Math.atan2(smooth_x, smooth_y) * (180 / Math.PI)
		+ (isFieldCentric ? -imuAngle : 0)
	);

	function handleKeydown(e: KeyboardEvent) {
		const k = e.key.toLowerCase();
		if (k in keys) keys[k as keyof typeof keys] = true;
	}
	function handleKeyup(e: KeyboardEvent) {
		const k = e.key.toLowerCase();
		if (k in keys) keys[k as keyof typeof keys] = false;
	}

	// ── Animation loop ─────────────────────────────────────────────────────────
	// Lerps smooth_* toward targets and also integrates imuAngle from rotation.
	let rafId: number;
	const ROT_SPEED = 120; // degrees per second at full rx
	let lastTime = 0;

	function loop(ts: number) {
		const dt = lastTime === 0 ? 0 : Math.min((ts - lastTime) / 1000, 0.1);
		lastTime = ts;

		const k = Math.min(accel, 1);

		smooth_x  += (target_x  - smooth_x)  * k;
		smooth_y  += (target_y  - smooth_y)  * k;
		smooth_rx += (target_rx - smooth_rx) * k;

		// Snap to zero when very small to avoid float drift
		if (Math.abs(smooth_x)  < 0.001) smooth_x  = 0;
		if (Math.abs(smooth_y)  < 0.001) smooth_y  = 0;
		if (Math.abs(smooth_rx) < 0.001) smooth_rx = 0;

		// Rotate orientation based on smooth_rx, accumulate freely, no wrap
		imuAngle += smooth_rx * ROT_SPEED * dt;

		rafId = requestAnimationFrame(loop);
	}

	onMount(() => {
		window.addEventListener('keydown', handleKeydown);
		window.addEventListener('keyup', handleKeyup);
		rafId = requestAnimationFrame(loop);
		return () => {
			window.removeEventListener('keydown', handleKeydown);
			window.removeEventListener('keyup', handleKeyup);
			cancelAnimationFrame(rafId);
		};
	});

	function wheelColor(v: number) {
		if (v > 0.05) return 'var(--color-success, #10b981)';
		if (v < -0.05) return 'var(--color-error, #ef4444)';
		return 'var(--text-secondary)';
	}

	// Normalized -180..180 view of the unbounded imuAngle (for display & slider)
	let imuNorm = $derived(((imuAngle % 360) + 540) % 360 - 180);
	let imuDisplay = $derived(Math.round(imuNorm));

	// Slider handler: apply the delta so imuAngle stays unbounded
	let _prevSlider = 0;
	function onSliderInput(e: Event) {
		const next = Number((e.target as HTMLInputElement).value);
		const delta = next - imuNorm;
		// Unwrap the delta: if the user dragged past the ±180 edge pick the short path
		const unwrapped = ((delta + 540) % 360) - 180;
		imuAngle += unwrapped;
	}
</script>

<svelte:head>
	<title>Mecanum Simulator | FTC Blueprint</title>
	<meta name="description" content="Interactive mecanum drive kinematics simulator for FTC." />
</svelte:head>

<header class="post-header text-center">
	<div class="post-header-bg" aria-hidden="true"></div>
	<div class="container container--narrow">
		<div class="animate-fade-up" style="margin-bottom: 1rem;">
			<span class="badge">Drive Systems</span>
		</div>
		<h1 class="post-title animate-fade-up" style="animation-delay:60ms; margin: 0 auto 1rem;">Mecanum Drive <span class="gradient-text">Simulator</span></h1>
		<p class="subtitle animate-fade-up" style="animation-delay:120ms">
			Press <strong>W A S D</strong> to strafe and translate, <strong>Q E</strong> to rotate.
			Watch the wheel power values update in real time.
		</p>
		<div class="title-rule animate-fade-up" style="animation-delay:180ms; margin: 1.5rem auto 0;" aria-hidden="true"></div>
	</div>
</header>

<section class="sim-page">
	<div class="container container--narrow">

		<div class="visualizer-wrap animate-fade-up" style="animation-delay: 100ms">
			<div class="vis-inner">

				<div class="chassis-area">
					<div class="chassis-label">Robot top view</div>

					<!-- North indicator sits outside and never rotates -->
					{#if isFieldCentric}
						<div class="field-north">
							<span class="north-label">N</span>
							<div class="north-arrow"></div>
						</div>
					{/if}

					<!-- The whole chassis rotates in field-centric mode -->
					<div
						class="robot-chassis"
						style={isFieldCentric ? `transform: rotate(${imuAngle}deg)` : ''}
					>
						<!-- Movement vector arrow: always centered, world-space direction -->
						{#if Math.max(Math.abs(smooth_x), Math.abs(smooth_y)) > 0.01}
							<div
								class="move-vector"
								style="transform: translate(-50%, -100%) rotate({arrowAngleDeg}deg)"
							></div>
						{/if}

						<!-- Rotation indicator -->
						{#if Math.abs(smooth_rx) > 0.01}
							<div class="rot-indicator" style="transform: translate(-50%,-50%) scaleX({smooth_rx < 0 ? 1 : -1})">
								<svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
									<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/>
									<path d="M3 3v5h5"/>
								</svg>
							</div>
						{/if}

						<!-- Wheels -->
						{#each [
							{ pos: 'fl', val: fl_n, label: 'FL' },
							{ pos: 'fr', val: fr_n, label: 'FR' },
							{ pos: 'bl', val: bl_n, label: 'BL' },
							{ pos: 'br', val: br_n, label: 'BR' }
						] as w}
							<div class="wheel wheel-{w.pos}">
								<div class="wheel-bar" style="height: {Math.abs(w.val) * 40}px; background: {wheelColor(w.val)}; {w.val < 0 ? 'margin-top: auto;' : ''}"></div>
								<span class="wheel-label">{w.label}</span>
								<span class="wheel-val" style="color: {wheelColor(w.val)}">{w.val.toFixed(2)}</span>
							</div>
						{/each}
					</div>
				</div>

				<!-- Right panel -->
				<div class="right-panel">
					<div class="equations-block">
						<p class="panel-label">Live kinematics</p>
						{#each [
							{ label: 'fl', val: fl_n, expr: `y + x + rx` },
							{ label: 'fr', val: fr_n, expr: `y − x − rx` },
							{ label: 'bl', val: bl_n, expr: `y − x + rx` },
							{ label: 'br', val: br_n, expr: `y + x − rx` }
						] as eq}
							<div class="eq-row" class:eq-active={Math.abs(eq.val) > 0.01}>
								<code class="eq-name">{eq.label}</code>
								<code class="eq-expr">({eq.expr}) / denom</code>
								<code class="eq-result" style="color: {wheelColor(eq.val)}">{eq.val.toFixed(2)}</code>
							</div>
						{/each}
					</div>

					<div class="inputs-block">
						<p class="panel-label">Input state</p>
						<div class="axis-row">
							<div class="axis-pill"><span>y</span><strong>{smooth_y.toFixed(2)}</strong></div>
							<div class="axis-pill"><span>x</span><strong>{smooth_x.toFixed(2)}</strong></div>
							<div class="axis-pill"><span>rx</span><strong>{smooth_rx.toFixed(2)}</strong></div>
						</div>
						<div class="keyboard">
							<div class="kb-row">
								<kbd class:active={keys.q}>Q</kbd>
								<kbd class:active={keys.w}>W</kbd>
								<kbd class:active={keys.e}>E</kbd>
							</div>
							<div class="kb-row">
								<kbd class:active={keys.a}>A</kbd>
								<kbd class:active={keys.s}>S</kbd>
								<kbd class:active={keys.d}>D</kbd>
							</div>
						</div>
					</div>

					<!-- Acceleration slider (always visible) -->
					<div class="accel-block">
						<p class="panel-label" style="margin-bottom: 0.5rem;">Acceleration smoothing</p>
						<div class="accel-row">
							<span class="accel-label">Smooth</span>
							<input
								type="range"
								min="0.05"
								max="1"
								step="0.01"
								bind:value={accel}
								class="accel-range"
							/>
							<span class="accel-label">Instant</span>
						</div>
						<div class="accel-val">{(accel * 100).toFixed(0)}%</div>
					</div>

					<div class="field-centric-block">
						<label class="toggle-row">
							<input type="checkbox" bind:checked={isFieldCentric} />
							<span class="toggle-track"><span class="toggle-thumb"></span></span>
							<span class="toggle-text">Field-centric mode</span>
						</label>
						{#if isFieldCentric}
							<div class="imu-row">
								<span>IMU heading</span>
								<code>{imuDisplay}°</code>
							</div>
							<input type="range" min="-180" max="180" value={imuNorm} oninput={onSliderInput} class="imu-range" />
						{/if}
					</div>
				</div>
			</div>

			<!-- Virtual D-pad (mobile only) -->
			<div class="virtual-dpad">
				<p class="panel-label" style="text-align:center; margin-bottom: 0.75rem;">Virtual joystick</p>
				<div class="dpad-grid">
					<button class="v-btn up" onpointerdown={() => (keys.w = true)} onpointerup={() => (keys.w = false)} onpointerleave={() => (keys.w = false)} oncontextmenu={(e) => e.preventDefault()}>▲</button>
					<button class="v-btn left" onpointerdown={() => (keys.a = true)} onpointerup={() => (keys.a = false)} onpointerleave={() => (keys.a = false)} oncontextmenu={(e) => e.preventDefault()}>◀</button>
					<button class="v-btn down" onpointerdown={() => (keys.s = true)} onpointerup={() => (keys.s = false)} onpointerleave={() => (keys.s = false)} oncontextmenu={(e) => e.preventDefault()}>▼</button>
					<button class="v-btn right" onpointerdown={() => (keys.d = true)} onpointerup={() => (keys.d = false)} onpointerleave={() => (keys.d = false)} oncontextmenu={(e) => e.preventDefault()}>▶</button>
				</div>
				<div class="rotate-row">
					<button class="v-btn rotate-btn" onpointerdown={() => (keys.q = true)} onpointerup={() => (keys.q = false)} onpointerleave={() => (keys.q = false)} oncontextmenu={(e) => e.preventDefault()}>↺ Q</button>
					<button class="v-btn rotate-btn" onpointerdown={() => (keys.e = true)} onpointerup={() => (keys.e = false)} onpointerleave={() => (keys.e = false)} oncontextmenu={(e) => e.preventDefault()}>↻ E</button>
				</div>
			</div>
		</div>

		<div class="content animate-fade-up" style="animation-delay: 200ms">
			<h2>How it Works</h2>
			<div class="grid-2">
				<div class="card">
					<h3>The kinematics</h3>
					<p>
						Each mecanum wheel has rollers at 45°, so forces decompose into X and Y components.
						The equations combine your translational inputs (<strong>x</strong>, <strong>y</strong>) and
						rotation (<strong>rx</strong>) into per-wheel powers that sum correctly.
					</p>
				</div>
				<div class="card">
					<h3>Field-centric mode</h3>
					<p>
						In robot-centric mode, <strong>W</strong> always drives the robot forward. In field-centric,
						the IMU heading rotates the input vector so <strong>W</strong> always drives away from the
						driver, the robot body rotates to show its real heading.
					</p>
				</div>
				<div class="card">
					<h3>Power normalization</h3>
					<p>
						The denominator is <code>max(|y| + |x| + |rx|, 1)</code>. When the raw sum exceeds 1, all
						four wheels are scaled proportionally so the fastest wheel always runs at full power.
					</p>
				</div>
				<div class="card">
					<h3>Strafing diagonally</h3>
					<p>
						Press <strong>W + D</strong> simultaneously. Two wheels drive forward, two receive zero
						power, the robot slides diagonally. This is unique to mecanum and impossible with
						standard tank drive.
					</p>
				</div>
			</div>

			<div class="callout animate-fade-up" style="animation-delay: 300ms">
				<h3>Ready to implement this on your robot?</h3>
				<p>
					Our full mecanum drive guide covers the math, Java implementation, and tips for
					calibrating field-centric mode with a BNO055 IMU.
				</p>
				<a href="/software/mecanum-drivetrain" class="btn">View Mecanum Guide →</a>
			</div>
		</div>

	</div>
</section>

<style>
	.sim-page { padding: 3rem 0 6rem; }

	.post-header {
		position: relative;
		padding: 4rem 0 3rem;
		border-bottom: 1px solid var(--border-subtle);
		background: var(--gradient-hero);
		overflow: hidden;
		text-align: center;
	}

	.post-header .container {
		position: relative;
		z-index: 1;
		display: flex;
		flex-direction: column;
		align-items: center;
	}

	.post-header h1 {
		font-size: clamp(2.5rem, 8vw, 4rem);
		font-weight: 800;
		line-height: 1.1;
		max-width: 800px;
	}

	.title-rule {
		height: 2px;
		background: var(--text-primary);
		border-radius: 0;
		width: 60px;
		opacity: 0.6;
	}
	.gradient-text {
		background: var(--text-primary);
		-webkit-background-clip: text;
		background-clip: text;
		-webkit-text-fill-color: transparent;
	}
	.subtitle {
		font-size: 1.15rem;
		color: var(--text-secondary);
		max-width: 600px;
		margin: 0 auto;
		line-height: 1.6;
	}
	.badge {
		display: inline-block;
		padding: 0.3rem 0.8rem;
		background: rgba(116, 215, 237, 0.1);
		color: var(--accent-cyan);
		border-radius: var(--radius-pill);
		font-size: 0.75rem;
		font-family: var(--font-mono);
		text-transform: uppercase;
		letter-spacing: 0.05em;
	}

	.visualizer-wrap {
		background: var(--bg-card);
		border: 1px solid var(--border);
		border-radius: var(--radius-xl);
		padding: 2rem;
		margin-bottom: 4rem;
	}
	.vis-inner {
		display: grid;
		grid-template-columns: 1fr;
		gap: 2.5rem;
	}
	@media (min-width: 720px) {
		.vis-inner { grid-template-columns: auto 1fr; align-items: start; }
	}

	/* Chassis area */
	.chassis-area {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.5rem;
	}
	.chassis-label {
		font-size: 0.75rem;
		font-family: var(--font-mono);
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--text-secondary);
	}

	/* North indicator: fixed, never rotates */
	.field-north {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 2px;
		margin-bottom: 4px;
	}
	.north-label {
		font-size: 0.65rem;
		font-family: var(--font-mono);
		color: var(--accent-cyan);
	}
	.north-arrow {
		width: 0; height: 0;
		border-left: 5px solid transparent;
		border-right: 5px solid transparent;
		border-bottom: 10px solid var(--accent-cyan);
	}

	/* Robot chassis: this rotates */
	.robot-chassis {
		position: relative;
		width: 148px;
		height: 188px;
		background: rgba(14, 165, 233, 0.07);
		border: 2px solid rgba(56, 189, 248, 0.35);
		border-radius: 0;
		margin: 0 20px 28px;
		transition: transform 0.08s linear;
	}

	/* Movement vector: pivot at bottom-center so it points away from center */
	.move-vector {
		position: absolute;
		top: 50%;
		left: 50%;
		width: 3px;
		height: 60px;
		background: var(--text-primary);
		/* transform-origin default is 50% 50% of the element.
		   We shift the element so its bottom sits on the chassis center,
		   then rotate around that bottom edge. */
		transform-origin: bottom center;
		border-radius: 0;
	}
	.move-vector::before {
		content: '';
		position: absolute;
		top: -8px; left: -5px;
		width: 0; height: 0;
		border-left: 6px solid transparent;
		border-right: 6px solid transparent;
		border-bottom: 10px solid var(--text-primary);
	}

	.rot-indicator {
		position: absolute;
		top: 50%; left: 50%;
		color: var(--text-primary);
	}

	/* Wheels */
	.wheel {
		position: absolute;
		width: 22px;
		height: 52px;
		background: var(--bg-secondary);
		border: 1.5px solid var(--border);
		border-radius: 0;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: flex-end;
		overflow: visible;
		z-index: 10;
	}
	.wheel-bar {
		width: 10px;
		border-radius: 0;
		transition: height 0.1s, background 0.15s;
		min-height: 0;
	}
	.wheel-label {
		font-size: 0.6rem;
		font-family: var(--font-mono);
		color: var(--text-secondary);
		margin-top: 2px;
		margin-bottom: 2px;
	}
	.wheel-val {
		position: absolute;
		bottom: -22px;
		font-size: 0.65rem;
		font-family: var(--font-mono);
		background: var(--bg-card);
		border: 1px solid var(--border);
		padding: 1px 3px;
		border-radius: 0;
		white-space: nowrap;
		transition: color 0.15s;
	}
	.wheel-fl { top: 8px; left: -13px; }
	.wheel-fr { top: 8px; right: -13px; }
	.wheel-bl { bottom: 8px; left: -13px; }
	.wheel-br { bottom: 8px; right: -13px; }

	/* Right panel */
	.right-panel { display: flex; flex-direction: column; gap: 1.5rem; }

	.panel-label {
		font-size: 0.75rem;
		font-family: var(--font-mono);
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--text-secondary);
		margin: 0 0 0.75rem;
	}

	.equations-block {
		background: var(--bg-secondary);
		border: 1px solid var(--border);
		border-radius: var(--radius-md);
		padding: 1rem;
	}
	.eq-row {
		display: grid;
		grid-template-columns: 2.5rem 1fr auto;
		gap: 0.5rem;
		align-items: center;
		padding: 0.35rem 0.5rem;
		border-radius: 0;
		transition: background 0.15s;
		font-size: 0.82rem;
	}
	.eq-row.eq-active {
		background: rgba(14, 165, 233, 0.08);
		border-left: 2px solid #38bdf8;
		padding-left: 0.4rem;
	}
	.eq-name { font-family: var(--font-mono); font-weight: 700; color: var(--accent-cyan); }
	.eq-expr { font-family: var(--font-mono); color: var(--text-secondary); font-size: 0.78rem; }
	.eq-result { font-family: var(--font-mono); font-weight: 700; transition: color 0.15s; text-align: right; }

	.axis-row { display: flex; gap: 0.75rem; margin-bottom: 1rem; }
	.axis-pill {
		display: flex;
		flex-direction: column;
		align-items: center;
		background: var(--bg-secondary);
		border: 1px solid var(--border);
		border-radius: var(--radius-md);
		padding: 0.4rem 0.75rem;
		font-family: var(--font-mono);
		gap: 0.1rem;
	}
	.axis-pill span { font-size: 0.7rem; color: var(--text-secondary); }
	.axis-pill strong { font-size: 1.1rem; color: var(--text-primary); }

	.keyboard { display: flex; flex-direction: column; gap: 0.4rem; align-items: flex-start; }
	.kb-row { display: flex; gap: 0.4rem; }
	kbd {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 38px; height: 38px;
		background: var(--bg-secondary);
		border: 1.5px solid var(--border);
		border-radius: 0;
		font-family: var(--font-mono);
		font-size: 0.9rem;
		font-weight: 700;
		color: var(--text-secondary);
		box-shadow: 0 3px 0 var(--border);
		transition: all 0.08s;
		user-select: none;
	}
	kbd.active {
		background: #38bdf8;
		border-color: #0284c7;
		color: white;
		box-shadow: 0 0 0 #0284c7;
		transform: translateY(3px);
	}

	/* Acceleration block */
	.accel-block {
		background: var(--bg-secondary);
		border: 1px solid var(--border);
		border-radius: var(--radius-md);
		padding: 1rem;
	}
	.accel-row {
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}
	.accel-label {
		font-size: 0.72rem;
		font-family: var(--font-mono);
		color: var(--text-secondary);
		white-space: nowrap;
	}
	.accel-range {
		flex: 1;
		accent-color: var(--accent-cyan);
	}
	.accel-val {
		font-size: 0.78rem;
		font-family: var(--font-mono);
		color: var(--accent-cyan);
		text-align: center;
		margin-top: 0.3rem;
	}

	.field-centric-block {
		background: var(--bg-secondary);
		border: 1px solid var(--border);
		border-radius: var(--radius-md);
		padding: 1rem;
	}
	.toggle-row {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		cursor: pointer;
		user-select: none;
	}
	.toggle-row input[type='checkbox'] { display: none; }
	.toggle-track {
		position: relative;
		width: 36px; height: 20px;
		background: var(--border);
		border-radius: 0;
		transition: background 0.2s;
		flex-shrink: 0;
	}
	.toggle-row input:checked + .toggle-track { background: #38bdf8; }
	.toggle-thumb {
		position: absolute;
		top: 3px; left: 3px;
		width: 14px; height: 14px;
		background: white;
		border-radius: 50%;
		transition: transform 0.2s;
	}
	.toggle-row input:checked + .toggle-track .toggle-thumb { transform: translateX(16px); }
	.toggle-text { font-size: 0.9rem; color: var(--text-primary); font-weight: 600; }

	.imu-row {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-top: 0.85rem;
		font-size: 0.85rem;
		color: var(--text-secondary);
	}
	.imu-row code { font-family: var(--font-mono); color: var(--accent-cyan); }
	.imu-range { width: 100%; margin-top: 0.4rem; accent-color: var(--accent-cyan); }

	/* Virtual D-pad (mobile only) */
	.virtual-dpad {
		margin-top: 2rem;
		padding-top: 1.5rem;
		border-top: 1px solid var(--border);
		display: flex;
		flex-direction: column;
		align-items: center;
	}
	@media (min-width: 720px) { .virtual-dpad { display: none; } }

	.dpad-grid {
		display: grid;
		grid-template-columns: 52px 52px 52px;
		grid-template-rows: 52px 52px;
		gap: 6px;
		grid-template-areas: '. up .' 'left down right';
		margin-bottom: 0.75rem;
	}
	.dpad-grid .up    { grid-area: up; }
	.dpad-grid .left  { grid-area: left; }
	.dpad-grid .down  { grid-area: down; }
	.dpad-grid .right { grid-area: right; }

	.rotate-row { display: flex; gap: 0.75rem; }
	.rotate-btn { padding: 0.5rem 1.25rem !important; font-size: 0.85rem !important; }

	.v-btn {
		background: var(--bg-secondary);
		border: 1.5px solid var(--border);
		border-radius: 0;
		color: var(--text-primary);
		font-family: var(--font-mono);
		font-size: 1.1rem;
		font-weight: 700;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		user-select: none;
		-webkit-user-select: none;
		touch-action: none;
		box-shadow: 0 3px 0 var(--border);
		transition: transform 0.08s, box-shadow 0.08s, background 0.08s;
	}
	.v-btn:active {
		transform: translateY(3px);
		box-shadow: 0 0 0 var(--border);
		background: rgba(56, 189, 248, 0.2);
	}

	/* Content section */
	.content { margin-top: 0; }
	.content h2 { font-size: 1.75rem; font-weight: 700; text-align: center; margin-bottom: 2rem; }

	.grid-2 {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
		gap: 1.5rem;
		margin-bottom: 3rem;
	}
	.card {
		background: var(--bg-card);
		border: 1px solid var(--border);
		padding: 1.75rem;
		border-radius: var(--radius-lg);
	}
	.card h3 { margin-bottom: 0.75rem; color: var(--accent-cyan); font-size: 1rem; font-weight: 700; }
	.card p { color: var(--text-body); font-size: 0.95rem; line-height: 1.65; margin: 0; }
	.card code {
		font-family: var(--font-mono);
		font-size: 0.85em;
		background: var(--bg-secondary);
		padding: 1px 5px;
		border-radius: 0;
	}

	.callout {
		background: var(--gradient-hero);
		border: 1px solid var(--border-subtle);
		padding: 3rem 2rem;
		border-radius: var(--radius-xl);
		text-align: center;
		margin-top: 1rem;
	}
	.callout h3 { font-size: 1.3rem; font-weight: 700; margin-bottom: 0.75rem; }
	.callout p {
		color: var(--text-secondary);
		margin-bottom: 2rem;
		max-width: 480px;
		margin-left: auto;
		margin-right: auto;
		line-height: 1.6;
	}
	.btn {
		display: inline-block;
		padding: 0.8rem 1.8rem;
		background: var(--text-primary);
		color: white;
		border-radius: var(--radius-md);
		text-decoration: none;
		font-weight: 600;
		transition: transform 0.2s;
	}
	.btn:hover { transform: translateY(-2px); }
</style>