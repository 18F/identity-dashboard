import { buildEmailAddressRow } from "./email_row";

const emailAddressList = () => document.querySelector("#user_email_list");

export const updateEmailAddressList = (emails, removeEmailCallback) => {
  const list = emailAddressList();
  list.innerHTML = "";
  emails.forEach((email) => {
    const row = buildEmailAddressRow(email, removeEmailCallback);
    list.append(row);
  });
};
