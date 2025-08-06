export function Required(props: { required: boolean }) {
	return props.required ? (
		<span class="label-text-alt text-error">Required</span>
	) : (
		<span class="label-text-alt">Optional</span>
	);
}
