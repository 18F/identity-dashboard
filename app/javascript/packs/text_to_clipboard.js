function textToClipboard(element) {
  const message = element.querySelector('.clipboard-message');
  const button = element.querySelector('button');
  const input = element.querySelector('.clipboard-input');
  if (!(message && input && button)) { return; }

  button.addEventListener('click', (_e) => {
    navigator.clipboard.writeText(input.value);
    message.innerHTML = 'Copied to clipboard!';
    message.classList.add('opacity-100');
    message.classList.remove('opacity-0');
    setTimeout(() => {
      message.classList.add('opacity-0');
      message.classList.remove('opacity-100');
    }, 2000);
  });
}

window.addEventListener('DOMContentLoaded', () => {
  for (const item of document.getElementsByClassName('text-to-clipboard-wrapper')) {
    textToClipboard(item);
  }
});
