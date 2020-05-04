import { buildEmailAddressRow } from "./email_row";
import { buildEmailAddressFormInput } from "./email_form_input";

const emailAddressList = () => document.querySelector("#user_email_list");
const emailAddressInputs = () => document.querySelector("#user_email_inputs");

export const updateEmailAddressList = () => {
  const list = emailAddressList();
  const hiddenInputs = emailAddressInputs();

  list.innerHTML = "";
  hiddenInputs.innerHTML = "";

  window.manageUserEmailAddresses.forEach((email) => {
    const row = buildEmailAddressRow(email);
    const input = buildEmailAddressFormInput(email);
    list.append(row);
    hiddenInputs.append(input);
  });
};
