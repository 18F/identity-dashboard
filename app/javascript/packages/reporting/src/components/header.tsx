import { VNode } from "preact";
import { getFullPath, Link } from "../router";
// eslint-disable-next-line import/no-relative-packages
import logoURL from "../../node_modules/identity-style-guide/dist/assets/img/login-gov-logo.svg";
// eslint-disable-next-line import/no-relative-packages
import closeURL from "../../node_modules/identity-style-guide/dist/assets/img/close.svg";

import ALL_ROUTES from "../routes/all";

interface HeaderProps {
  path: string;
}

function Header({ path }: HeaderProps): VNode {
  return (
    <header className="usa-header usa-header--extended">
      <div className="usa-navbar">
        <div className="usa-logo">
          <Link href="/" title="Home" aria-label="Home">
            <img src={logoURL} className="usa-logo__img" alt="Login.gov" />
            <em className="usa-logo__text">
              Data
              <span className="usa-tag bg-blue margin-left-05">Beta</span>
            </em>
          </Link>
        </div>
        <button className="usa-menu-btn" type="button">
          Menu
        </button>
      </div>
      <nav className="usa-nav">
        <div className="usa-nav__inner">
          <button className="usa-nav__close" type="button">
            <img src={closeURL} alt="Close" />
          </button>
          <ul className="usa-nav__primary usa-accordion">
            {Object.entries(ALL_ROUTES).map(([routePath, title]) => (
              <li className="usa-nav__primary-item">
                <Link
                  href={routePath}
                  className={path === getFullPath(routePath) ? "usa-current" : undefined}
                >
                  {title}
                </Link>
              </li>
            ))}
          </ul>
        </div>
      </nav>
    </header>
  );
}

export default Header;
