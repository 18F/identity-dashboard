declare module "*.svg";

declare module "identity-style-guide" {
  interface Component {
    on: () => void;
  }

  const accordion: Component;
  const banner: Component;
  const navigation: Component;
}
