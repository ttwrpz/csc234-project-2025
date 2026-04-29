/* eslint-env node */
module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    project: './tsconfig.eslint.json',
    tsconfigRootDir: __dirname,
    sourceType: 'module',
    ecmaVersion: 2022,
  },
  plugins: ['@typescript-eslint'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:@typescript-eslint/recommended-requiring-type-checking',
  ],
  ignorePatterns: ['lib/**', 'node_modules/**', 'jest.config.cjs', '.eslintrc.cjs'],
  rules: {
    'no-console': 'error',
    '@typescript-eslint/no-floating-promises': 'error',
    '@typescript-eslint/no-explicit-any': 'error',
    'no-restricted-imports': [
      'error',
      {
        paths: [
          {
            name: 'firebase-functions',
            importNames: ['config'],
            message: 'Use defineSecret from firebase-functions/params',
          },
          {
            name: 'firebase-functions/v1',
            message:
              'Use the v2 API entrypoints (firebase-functions/v2/https, firebase-functions/params, firebase-functions/logger).',
          },
        ],
        patterns: ['firebase-functions/v1/*'],
      },
    ],
  },
  overrides: [
    {
      files: ['src/__tests__/**/*.ts'],
      rules: {
        '@typescript-eslint/no-explicit-any': 'off',
        '@typescript-eslint/no-unsafe-assignment': 'off',
        '@typescript-eslint/no-unsafe-member-access': 'off',
        '@typescript-eslint/no-unsafe-call': 'off',
        '@typescript-eslint/no-unsafe-return': 'off',
        '@typescript-eslint/no-unsafe-argument': 'off',
        '@typescript-eslint/unbound-method': 'off',
        'no-restricted-imports': 'off',
      },
    },
  ],
};
