import {
  setupManageUsersTestDOM,
  tearDownManageUsersTestDOM,
} from "../../support/manage_users/dom";

import { buildEmailAddressFormInput } from "../../../../app/javascript/app/manage_users/email_form_input";

describe("manage_users/email_form_input", () => {
  beforeEach(() => {
    setupManageUsersTestDOM();
  });

  afterEach(() => {
    tearDownManageUsersTestDOM();
  });

  describe(".buildEmailAddressFormInput", () => {
    it("returns a hidden input with the correct attributes", () => {
      const input = buildEmailAddressFormInput("test@gsa.gov");

      expect(input.type).to.eq("hidden");
      expect(input.name).to.eq("user_emails[]");
      expect(input.className).to.eq("user_email_input");
      expect(input.value).to.eq("test@gsa.gov");
    });
  });
});
