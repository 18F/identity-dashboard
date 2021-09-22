import {
  setupManageUsersTestDOM,
  tearDownManageUsersTestDOM,
} from "../../support/manage_users/dom";

import { updateEmailAddressList } from "../../../../app/javascript/app/manage_users/email_list";

describe("manage_user/email_list", () => {
  beforeEach(() => {
    setupManageUsersTestDOM();
  });

  afterEach(() => {
    tearDownManageUsersTestDOM();
  });

  describe(".updateEmailAddressList", () => {
    it("adds list rows and inputs for emails addresses to the page", () => {
      window.manageUserEmailAddresses = ["test1@gsa.gov", "test2@gsa.gov"];

      updateEmailAddressList();

      const list = document.querySelector("#user_email_list");

      expect(list.textContent).to.have.string("test1@gsa.gov");
      expect(list.textContent).to.have.string("test2@gsa.gov");

      const hiddenInputs = document.querySelectorAll('input[name="user_emails[]"]');
      const hiddenInputsEmails = Array.from(hiddenInputs).map((i) => i.value);

      expect(hiddenInputsEmails).to.deep.equal(["test1@gsa.gov", "test2@gsa.gov"]);
    });

    it("updates the list correctly on subsequent calls", () => {
      window.manageUserEmailAddresses = ["test1@gsa.gov", "test2@gsa.gov"];
      updateEmailAddressList();
      window.manageUserEmailAddresses = ["test2@gsa.gov", "test3@gsa.gov"];
      updateEmailAddressList();

      const list = document.querySelector("#user_email_list");

      expect(list.textContent).to.not.have.string("test1@gsa.gov");
      expect(list.textContent).to.have.string("test2@gsa.gov");
      expect(list.textContent).to.have.string("test3@gsa.gov");

      const hiddenInputs = document.querySelectorAll('input[name="user_emails[]"]');
      const hiddenInputsEmails = Array.from(hiddenInputs).map((i) => i.value);

      expect(hiddenInputsEmails).to.deep.equal(["test2@gsa.gov", "test3@gsa.gov"]);
    });
  });
});
