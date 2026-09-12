<script lang="ts">
	import { fade } from 'svelte/transition';

	let isSubmitting = $state(false);
	let isSent = $state(false);
	let submitText = $state('Send Code');

	async function handleSubmit(e: Event) {
		e.preventDefault();
		if (isSubmitting || isSent) return;

		isSubmitting = true;
		submitText = 'Sending...';

		const form = e.target as HTMLFormElement;
		const formData = new FormData(form);
		const object = Object.fromEntries(formData.entries());
		const json = JSON.stringify(object);

		try {
			const response = await fetch('https://api.web3forms.com/submit', {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
					Accept: 'application/json'
				},
				body: json
			});

			const result = await response.json();
			if (response.ok && result.success) {
				isSent = true;
				form.reset();
				setTimeout(() => {
					isSent = false;
					submitText = 'Send Code';
				}, 5000);
			} else {
				console.error('Web3Forms error:', result);
				submitText = 'Error!';
				setTimeout(() => (submitText = 'Send Code'), 3000);
			}
		} catch (error) {
			console.error(error);
			submitText = 'Error!';
			setTimeout(() => (submitText = 'Send Code'), 3000);
		} finally {
			isSubmitting = false;
		}
	}
</script>

<section class="review-section animate-fade-up">
	{#if isSent}
		<div class="success-message" transition:fade>
			<div class="success-icon">✓</div>
			<h3>Code Received!</h3>
			<p>We'll get back to you shortly at the email provided.</p>
		</div>
	{:else}
		<div class="review-content">
			<div class="text-side">
				<h2>Code Review</h2>
				<p>Share your code with us! We'll give you detailed feedback on your <strong>logic, structure, and bugs.</strong></p>
				<p class="reminder-box">
					<strong>Reminder:</strong> Make sure your repository is <code class="email-code">public</code> or share access with <code class="email-code">ftcblueprint@gmail.com</code>.
				</p>
			</div>

			<div class="form-side">
				<form onsubmit={handleSubmit} class="review-form">
					<input type="hidden" name="access_key" value="3dd53572-82f6-44ed-b36f-7e8cdef9c21a" />
					<input type="hidden" name="subject" value="New Code Review Request" />

					<div class="form-row">
						<input type="text" name="team" placeholder="Team Name & Number" required />
						<input type="email" name="email" placeholder="Contact Email" required />
					</div>
					<input type="url" name="code_link" placeholder="GitHub repository link" required />
					<textarea name="notes" placeholder="Notes (specific files, bugs, areas to focus on...)" rows="3"></textarea>

					<button type="submit" class="btn-submit" disabled={isSubmitting}>{submitText}</button>
				</form>
			</div>
		</div>
	{/if}
</section>

<style>
	.review-section {
		padding: 2.5rem;
		background: var(--bg-card);
		border: 1px solid var(--border);
		border-radius: var(--radius-lg);
		box-shadow: 0 4px 24px rgba(0,0,0,0.06);
	}

	.review-content {
		display: flex;
		gap: 2.5rem;
		align-items: flex-start;
		flex-wrap: wrap;
	}

	.text-side {
		flex: 1;
		min-width: 240px;
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	h2 {
		font-size: 1.75rem;
		margin: 0;
		color: var(--text-primary);
	}

	p {
		color: var(--text-secondary);
		line-height: 1.55;
		font-size: 0.95rem;
		margin: 0;
	}

	.reminder-box {
		font-size: 0.85rem;
		padding: 0.75rem 1rem;
		background: rgba(26, 122, 149, 0.08);
		border-left: 3px solid var(--accent-cyan);
		border-radius: 0;
	}

	.email-code {
		background: var(--bg-secondary);
		padding: 0.1rem 0.3rem;
		border-radius: 0;
		font-family: var(--font-mono);
		font-size: 0.9em;
		color: var(--accent-cyan);
	}

	.form-side {
		flex: 1.4;
		min-width: 300px;
	}

	.review-form {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.form-row {
		display: flex;
		gap: 0.75rem;
		flex-wrap: wrap;
	}

	.form-row input { flex: 1; min-width: 140px; }

	input, textarea {
		padding: 0.75rem 0.9rem;
		background: var(--bg-secondary);
		border: 1px solid var(--border);
		border-radius: var(--radius-md);
		color: var(--text-primary);
		font-family: var(--font-body);
		font-size: 0.9rem;
		transition: all var(--transition-fast);
		width: 100%;
		box-sizing: border-box;
	}

	input:focus, textarea:focus {
		outline: none;
		border-color: var(--accent-cyan);
		box-shadow: 0 0 0 3px rgba(26, 122, 149, 0.1);
	}

	.btn-submit {
		width: 100%;
		padding: 0.85rem;
		background: var(--accent-green);
		color: #151515;
		border: none;
		border-radius: var(--radius-md);
		font-weight: 700;
		font-size: 0.95rem;
		cursor: pointer;
		transition: all var(--transition-fast);
		margin-top: 0.25rem;
	}

	.btn-submit:hover { filter: brightness(1.1); transform: none; }
	.btn-submit:disabled { opacity: 0.6; cursor: not-allowed; transform: none; }

	.success-message {
		text-align: center;
		padding: 2rem 0;
	}

	.success-icon {
		width: 44px;
		height: 44px;
		background: var(--accent-green);
		color: #000;
		border-radius: 0;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		font-weight: bold;
		font-size: 1.2rem;
		margin-bottom: 1rem;
	}

	@media (max-width: 480px) {
		.form-row { flex-direction: column; }
	}
</style>
