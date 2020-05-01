import sinon from "sinon";

import {
  setupManageUsersTestDOM,
  tearDownManageUsersTestDOM,
} from "../../support/manage_users/dom";

import { updateEmailAddressList } from "../../../../app/javascript/app/manage_users/email_list";

const INITIAL_HTML = `
<ul id='user_email_list'></ul>
`;

describe("manage_user/email_list", () => {
  beforeEach(() => {
    setupManageUsersTestDOM();
  });

  afterEach(() => {
    tearDownManageUsersTestDOM();
  });

  describe(".updateEmailAddressList", () => {
    it("adds the emails addresses to the list on the page", () => {
      const emails = ["test1@gsa.gov", "test2@gsa.gov"];

      updateEmailAddressList(emails, () => {});

      const list = document.querySelector("#user_email_list");

      expect(list.textContent).to.have.string("test1@gsa.gov");
      expect(list.textContent).to.have.string("test2@gsa.gov");
    });

    it("updates the list correctly on subsequent calls", () => {
      const emails1 = ["test1@gsa.gov", "test2@gsa.gov"];
      const emails2 = ["test2@gsa.gov", "test3@gsa.gov"];

      updateEmailAddressList(emails1, () => {});
      updateEmailAddressList(emails2, () => {});

      const list = document.querySelector("#user_email_list");

      expect(list.textContent).to.not.have.string("test1@gsa.gov");
      expect(list.textContent).to.have.string("test2@gsa.gov");
      expect(list.textContent).to.have.string("test3@gsa.gov");
    });

    it("adds the remove email callback to list items", () => {
      const removeEmailCallback = sinon.spy();

      const emails1 = ["test1@gsa.gov", "test2@gsa.gov"];

      updateEmailAddressList(emails1, removeEmailCallback);

      const list = document.querySelector("#user_email_list");
      const firstRow = list.children[0];
      const link = firstRow.querySelector("a");

      link.onclick({ preventDefault: () => {} });

      expect(removeEmailCallback.calledOnce).to.eq(true);
      expect(removeEmailCallback.firstCall.args[0]).to.eq("test1@gsa.gov");
    });
  });
});
