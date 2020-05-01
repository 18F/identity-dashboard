import { addEmailAddressToList } from "./actions";

export const setupAddEmailForm = () => {
  const button = document.getElementById("add_email_button");
  button.onclick = () => {
    const email = document.getElementById("add_email").value;
    if (!email) return;
    addEmailAddressToList(email);
    document.getElementById("add_email").value = "";
  };
};
