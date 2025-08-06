import { defineConfig, devices } from '@playwright/test';

/**
 * Read environment variables from file.
 * https://github.com/motdotla/dotenv
 */
// import dotenv from 'dotenv';
// import path from 'path';
// dotenv.config({ path: path.resolve(__dirname, '.env') });

/**
 * See https://playwright.dev/docs/test-configuration.
 */
const isCI = !!process.env['CI'];

export default defineConfig({
  testDir: './tests',
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: isCI,
  /* Retry on CI only */
  retries: isCI ? 4 : 0,
  /* Opt out of parallel tests on CI. */
  ...(isCI ? { workers: 5 } : {}),
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: [['list',{}],['html',{open: 'never'}]],
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    // baseURL: 'http://localhost:3000',
     launchOptions: {
          slowMo: process.env['PW_SLOW_MO'] ? Number(process.env['PW_SLOW_MO']) : 0, // Use PW_SLOW_MO if set, otherwise 0
          args: [
              '--no-sandbox',
              '--disable-dev-shm-usage',
              '--disable-gpu',
              '--disable-web-security',
              '--disable-setuid-sandbox',
              '--disable-background-timer-throttling',
              '--disable-backgrounding-occluded-windows',
              '--disable-renderer-backgrounding',
              '--disable-features=TranslateUI',
              '--disable-features=MediaFoundationVideoCapture',
              '--disable-ipc-flooding-protection',
              '--no-first-run',
              '--disable-default-apps',
              '--disable-extensions',
              '--disable-plugins',
              '--disable-sync',
              '--disable-translate',
              '--hide-scrollbars',
              '--mute-audio',
              '--no-default-browser-check',
              '--no-first-run',
              '--disable-software-rasterizer',
              '--disable-background-networking',
              '--disable-backgrounding-occluded-windows',
              '--disable-client-side-phishing-detection',
              '--disable-component-update',
              '--disable-default-apps',
              '--disable-domain-reliability',
              '--disable-features=AudioServiceOutOfProcess',
              '--disable-hang-monitor',
              '--disable-popup-blocking',
              '--disable-prompt-on-repost',
              '--disable-web-resources',
              '--enable-automation',
              '--enable-logging',
              '--log-level=0'
          ]

        },
    headless: true,
    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    baseURL: process.env['PW_BASE_URL'],
    actionTimeout: 30000,
    navigationTimeout: 30000,
  },

  /* Configure projects for major browsers */
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1920, height: 1080 },
      },
    },

    // {
    //   name: 'firefox',
    //   use: { ...devices['Desktop Firefox'] },
    // },

    // {
    //   name: 'webkit',
    //   use: { ...devices['Desktop Safari'] },
    // },

    /* Test against mobile viewports. */
    // {
    //   name: 'Mobile Chrome',
    //   use: { ...devices['Pixel 5'] },
    // },
    // {
    //   name: 'Mobile Safari',
    //   use: { ...devices['iPhone 12'] },
    // },

    /* Test against branded browsers. */
    // {
    //   name: 'Microsoft Edge',
    //   use: { ...devices['Desktop Edge'], channel: 'msedge' },
    // },
    // {
    //   name: 'Google Chrome',
    //   use: { ...devices['Desktop Chrome'], channel: 'chrome' },
    // },
  ],

  /* Run your local dev server before starting the tests */
  // webServer: {
  //   command: 'npm run start',
  //   url: 'http://localhost:3000',
  //   reuseExistingServer: !process.env.CI,
  // },
});

