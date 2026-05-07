/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/*.test.ts', '**/*.spec.ts'],
  testTimeout: 30000,
  // Emulator tests share a single test environment per file via initializeTestEnvironment;
  // run sequentially so port 8080 is owned by exactly one suite at a time.
  maxWorkers: 1,
};
