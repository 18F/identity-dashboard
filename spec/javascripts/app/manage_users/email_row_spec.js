import sinon from "sinon";

import { setupTestDOM, teardDownTestDOM } from "../../support/dom";

import { buildEmailAddressRow } from "../../../../app/javascript/app/manage_users/email_row";

describe("manage_users/email_row", () => {
  before(() => {
    setupTestDOM();
  });

  after(() => {
    teardDownTestDOM();
  });

  describe("buildEmailAddressRow", () => {
    it("renders a row with the email address", () => {
      const row = buildEmailAddressRow("test@gsa.gov", () => {});

      expect(row.textContent).to.have.string("test@gsa.gov");
    });

    it("adds the remove email callback to the remove email link", () => {
      const removeEmailCallback = sinon.spy();
      const row = buildEmailAddressRow("test@gsa.gov", removeEmailCallback);
      const removeEmailLink = row.querySelector("a");

      expect(removeEmailLink.textContent).to.have.string("⨉");

      const clickEvent = { preventDefault: sinon.spy() };

      removeEmailLink.onclick(clickEvent);

      expect(removeEmailCallback.calledOnce).to.eq(true);
      expect(removeEmailCallback.lastCall.args[0]).to.eq("test@gsa.gov");
      expect(clickEvent.preventDefault.calledOnce).to.eq(true);
    });
  });
});
