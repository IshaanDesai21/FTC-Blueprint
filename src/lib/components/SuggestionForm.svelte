<script lang="ts">
	let isSubmitting = $state(false);
	let submitText = $state('Send Suggestion');

	async function handleSubmit(e: Event) {
		e.preventDefault();
		if (isSubmitting) return;

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
				submitText = 'Sent!';
				form.reset();
			} else {
				console.error('Web3Forms error:', result);
				submitText = 'Error!';
			}
		} catch (error) {
			console.error(error);
			submitText = 'Error!';
		}

		setTimeout(() => {
			submitText = 'Send Suggestion';
			isSubmitting = false;
		}, 3000);
	}
</script>

<div class="suggestion-container animate-fade-up">
	<div class="form-header">
		<h3>Submit a Request</h3>
		<p>Have an idea for a guide or a tip? Let us know!</p>
	</div>

	<form class="suggestion-form" onsubmit={handleSubmit}>
		<input type="hidden" name="access_key" value="75203397-0013-44ac-bc8b-b7477ce9a056" />
		<input type="hidden" name="subject" value="New Suggestion / Guide Request" />

		<div class="form-group">
			<label for="topic">Topic / Request</label>
			<input
				type="text"
				id="topic"
				name="topic"
				placeholder="e.g., Roadrunner advanced tuning"
				required
			/>
		</div>

		<div class="form-group">
			<label for="email">Your Email</label>
			<input
				type="email"
				id="email"
				name="email"
				placeholder="your@email.com"
				required
			/>
		</div>

		<div class="form-group">
			<label for="link">Link (optional)</label>
			<input
				type="text"
				id="link"
				name="link"
				placeholder="GitHub repo, doc, video, etc."
			/>
		</div>

		<div class="form-group">
			<label for="message">Message</label>
			<textarea
				id="message"
				name="message"
				placeholder="Describe what you'd like to see..."
				rows="4"
				required
			></textarea>
		</div>

		<button type="submit" class="submit-btn" disabled={isSubmitting}>
			<span style="color: var(--bg);">{submitText}</span>
			<svg
				width="16"
				height="16"
				viewBox="0 0 24 24"
				fill="none"
				stroke="var(--bg)"
				stroke-width="2.5"
				stroke-linecap="round"
				stroke-linejoin="round"
				><line x1="22" y1="2" x2="11" y2="13"></line><polygon points="22 2 15 22 11 13 2 9 22 2"
				></polygon></svg
			>
		</button>
	</form>
</div>

<style>
	.suggestion-container {
		margin-top: 4rem;
		padding: 2rem;
		background: var(--bg-card);
		border: 1px solid var(--border);
		border-radius: var(--radius-lg);
		max-width: 600px;
	}

	.form-header {
		margin-bottom: 2rem;
	}

	.form-header h3 {
		margin-bottom: 0.5rem;
		font-size: 1.4rem;
	}

	.form-header p {
		color: var(--text-secondary);
		font-size: 0.9rem;
	}

	.suggestion-form {
		display: flex;
		flex-direction: column;
		gap: 1.5rem;
	}

	.form-group {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
	}

	.form-group label {
		font-size: 0.85rem;
		font-weight: 600;
		color: var(--text-primary);
		font-family: var(--font-body);
	}

	input,
	textarea {
		background: var(--bg-secondary);
		border: 1px solid var(--border);
		border-radius: var(--radius-md);
		padding: 0.8rem 1rem;
		color: var(--text-primary);
		font-family: var(--font-body);
		font-size: 0.95rem;
		transition:
			border-color var(--transition-fast),
			box-shadow var(--transition-fast),
			background-color var(--transition-base);
	}

	input:focus,
	textarea:focus {
		outline: none;
		border-color: var(--accent-green);
		box-shadow: 0 0 0 2px rgba(126, 255, 160, 0.1);
	}

	.submit-btn {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.75rem;
		padding: 0.85rem;
		background: var(--accent-green);
		color: #151515;
		border: none;
		border-radius: var(--radius-md);
		font-weight: 700;
		font-size: 0.95rem;
		cursor: pointer;
		transition: all var(--transition-fast);
		margin-top: 0.5rem;
	}

	.submit-btn:hover {
		transform: none;
		box-shadow: none;
		filter: brightness(1.1);
	}

	.submit-btn:active {
		transform: translateY(0);
	}
</style>
