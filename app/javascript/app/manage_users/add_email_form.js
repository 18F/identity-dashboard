import { addEmailAddressToList } from "./actions";

const addEmailInput = () => document.getElementById("add_email");

const addEmailButtonClicked = () => {
  const email = addEmailInput().value;
  if (!email) {
    return;
  }
  addEmailAddressToList(email);
  addEmailInput().value = "";
};

const shouldInterceptKeyPressEvent = (event) => {
  // 13 is the keycode for the enter key
  if (event.keyCode !== 13) {
    return false;
  }
  if (document.activeElement !== addEmailInput()) {
    return false;
  }
  return true;
};

const addEmailInputKeyPress = (event) => {
  if (!shouldInterceptKeyPressEvent(event)) {
    return;
  }
  event.preventDefault();
  addEmailButtonClicked();
};

export const setupAddEmailForm = () => {
  const button = document.getElementById("add_email_button");
  button.onclick = addEmailButtonClicked;

  addEmailInput().onkeypress = addEmailInputKeyPress;
};
