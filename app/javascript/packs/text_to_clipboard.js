class TextToClipboard {
  constructor(element) {
    const messagePlaceholder = element.getElementsByClassName('clipboard-message-placeholder')[0];
    const [button] = element.getElementsByTagName('button');
    [this.input] = element.getElementsByClassName('clipboard-input');
    if (!(messagePlaceholder && this.input && button)) { return; }

    this.message = document.createElement("span");
    this.message.innerHTML = "Copied to clipboard!";
    messagePlaceholder.append(this.message);
    button.addEventListener('click', (_e) => {
      navigator.clipboard.writeText(this.input.value);
      this.message.classList.add('is-visible');
      setTimeout(() => {
        this.message.classList.remove('is-visible');
      }, 2000);
    });
  }
}

window.addEventListener('DOMContentLoaded', () => {
  for (const item of document.getElementsByClassName('text-to-clipboard-wrapper')) {
    TextToClipboard(item);
  }
});
