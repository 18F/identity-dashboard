import { defineConfig } from "eslint/config";
// import 18fEslintPluginIdentity from "@18f/eslint-plugin-identity";
import EslintPluginImport from "eslint-plugin-import";
import globals from "globals";
// import path from "node:path";
// import { fileURLToPath } from "node:url";
// import js from "@eslint/js";
// import { FlatCompat } from "@eslint/eslintrc";

// const __filename = fileURLToPath(import.meta.url);
// const __dirname = path.dirname(__filename);
// const compat = new FlatCompat({
//     baseDirectory: __dirname,
//     recommendedConfig: js.configs.recommended,
//     allConfig: js.configs.all
// });

export default defineConfig([{
    // extends: compat.extends("plugin:@18f/eslint-plugin-identity/recommended"),

    plugins: {
        "import": EslintPluginImport,
    },

    languageOptions: {
        globals: {
            ...globals.browser,
            expect: true,
        },
    },

    rules: {
        "import/no-extraneous-dependencies": ["error", {
            devDependencies: ["{spec,config}/**/*"],
        }],
        'class-methods-use-this': 'off',
        'comma-dangle': 'off',
        'consistent-return': 'off',
        curly: ['error', 'all'],
        'func-names': 'off',
        'function-paren-newline': 'off',
        'prefer-arrow-callback': 'off',
        'import/prefer-default-export': 'off',
        'import/extensions': ['off', 'never'],
        'import/no-extraneous-dependencies': 'error',
        indent: 'off',
        'max-len': 'off',
        'max-classes-per-file': 'off',
        'newline-per-chained-call': 'off',
        'no-cond-assign': ['error', 'except-parens'],
        'no-console': 'error',
        'no-empty': ['error', { allowEmptyCatch: true }],
        'no-param-reassign': ['off', 'never'],
        'no-promise-executor-return': 'off',
        'no-confusing-arrow': 'off',
        'no-plusplus': 'off',
        'no-restricted-syntax': 'off',
        'no-unused-expressions': 'off',
        'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
        quotes: 'off',
        'implicit-arrow-linebreak': 'off',
        'object-curly-newline': 'off',
        'operator-linebreak': 'off',
        'require-await': 'error',
    },
}]);
