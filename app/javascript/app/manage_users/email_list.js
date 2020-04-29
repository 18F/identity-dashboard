import { buildEmailAddressRow } from "./email_row";

const emailAddressList = () => document.querySelector("#user_email_list");
const emailAddressInputs = () => document.querySelector("#user_email_inputs");

const buildHiddenInput = (email) => {
  const input = document.createElement("input");
  input.type = "hidden";
  input.name = "user_emails[]";
  input.value = email;
  return input;
};

export const updateEmailAddressList = (emails, removeEmailCallback) => {
  const list = emailAddressList();
  const hiddenInputs = emailAddressInputs();
  list.innerHTML = "";
  hiddenInputs.innerHTML = "";
  emails.forEach((email) => {
    const row = buildEmailAddressRow(email, removeEmailCallback);
    list.append(row);
    const input = buildHiddenInput(email);
    hiddenInputs.append(input);
  });
};
