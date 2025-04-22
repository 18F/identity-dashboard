function textToClipboard(element) {
  const messagePlaceholder = element.getElementsByClassName('clipboard-message-placeholder')[0];
  const [button] = element.getElementsByTagName('button');
  const [input] = element.getElementsByClassName('clipboard-input');
  if (!(messagePlaceholder && input && button)) { return; }

  const message = document.createElement("span");
  message.innerHTML = "Copied to clipboard!";
  messagePlaceholder.append(this.message);
  button.addEventListener('click', (_e) => {
    navigator.clipboard.writeText(input.value);
    message.classList.add('is-visible');
    setTimeout(() => {
      message.classList.remove('is-visible');
    }, 2000);
  });
}

window.addEventListener('DOMContentLoaded', () => {
  for (const item of document.getElementsByClassName('text-to-clipboard-wrapper')) {
    textToClipboard(item);
  }
});
