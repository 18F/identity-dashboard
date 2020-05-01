import sinon from "sinon";

import {
  setupManageUsersTestDOM,
  tearDownManageUsersTestDOM,
} from "../../support/manage_users/dom";

import {
  addEmailAddressToList,
  loadInitialEmailAddresses,
} from "../../../../app/javascript/app/manage_users/actions";

import { buildEmailAddressRow } from "../../../../app/javascript/app/manage_users/email_row";

describe("manage_users/email_row", () => {
  before(() => {
    setupManageUsersTestDOM();
    loadInitialEmailAddresses();
  });

  after(() => {
    tearDownManageUsersTestDOM();
  });

  describe(".buildEmailAddressRow", () => {
    it("renders a row with the email address", () => {
      const row = buildEmailAddressRow("test@gsa.gov");

      expect(row.textContent).to.have.string("test@gsa.gov");
    });

    it("adds the remove email callback to the remove email link", () => {
      addEmailAddressToList("test@gsa.gov");

      const row = buildEmailAddressRow("test@gsa.gov");
      const removeEmailLink = row.querySelector("a");

      expect(removeEmailLink.textContent).to.have.string("⨉");

      const clickEvent = { preventDefault: sinon.spy() };

      removeEmailLink.onclick(clickEvent);

      expect(window.manageUserEmailAddresses).to.not.include("test@gsa.gov");
      expect(clickEvent.preventDefault.calledOnce).to.eq(true);
    });
  });
});
