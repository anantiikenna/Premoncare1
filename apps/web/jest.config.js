const nextJest = require('next/jest')

const createJestConfig = nextJest({
  dir: './',
})

/** @type {import('jest').Config} */
const config = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.ts'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
    // Pin React to the single workspace-root copy (root package.json
    // overrides force one react/react-dom version; RTL hoists to root too).
    '^react$': '<rootDir>/../../node_modules/react',
    '^react/(.*)$': '<rootDir>/../../node_modules/react/$1',
    '^react-dom$': '<rootDir>/../../node_modules/react-dom',
    '^react-dom/(.*)$': '<rootDir>/../../node_modules/react-dom/$1',
  },
  testPathIgnorePatterns: ['<rootDir>/.next/', '<rootDir>/.opencode/', '<rootDir>/node_modules/'],
  collectCoverageFrom: [
    'src/lib/**/*.ts',
    'src/lib/**/*.tsx',
    'src/components/**/*.tsx',
    '!src/lib/types.ts',
    '!src/**/*.d.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 6,
      functions: 4,
      lines: 6,
      statements: 6,
    },
  },
}

module.exports = createJestConfig(config)
