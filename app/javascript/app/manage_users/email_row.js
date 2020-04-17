const buildListElement = () => {
  const node = document.createElement("li");
  node.classList = "margin-top-1";
  return node;
};

const buildSpanElement = () => {
  const node = document.createElement("span");
  node.classList = "bg-primary-lighter radius-lg inline-block padding-x-1 padding-y-05";
  return node;
};

const buildEmailAddressText = (email) => {
  return document.createTextNode(`${email} | `);
};

const buildRemoveEmailLink = (email, removeEmailCallback) => {
  const node = document.createElement("a");
  node.classList = "text-ink text-no-underline";
  node.href = "/";
  node.innerHTML = "⨉";
  node.onclick = (event) => {
    event.preventDefault();
    removeEmailCallback(email);
  };
  return node;
};

export const buildEmailAddressRow = (email, removeEmailCallback) => {
  const li = buildListElement();
  const span = buildSpanElement();
  const text = buildEmailAddressText(email);
  const link = buildRemoveEmailLink(email, removeEmailCallback);

  span.append(text);
  span.append(link);
  li.append(span);

  return li;
};
