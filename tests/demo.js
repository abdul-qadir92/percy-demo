(async () => {
  const puppeteer = require('puppeteer')
  const httpServer = require('http-server')
  const percySnapshot = require('@percy/puppeteer')

  const TEST_WIDTHS = [375, 768, 1280];

  // Start a local HTTP Server to host our TodoMVC app.
  const server = httpServer.createServer()
  const PORT = 8000
  server.listen(PORT)
  const URL = `http://localhost:${PORT}/assets`

  // Start a Puppeteer instance.
  const browser = await puppeteer.launch({
    args: [
      '--headless',
      // required to run puppeteer in docker
      '--no-sandbox'
    ]
  })
  const page = await browser.newPage();

  // Run tests
  await page.goto(`${URL}/signup`);

  await percySnapshot(page, 'Signup Page', {widths: TEST_WIDTHS});

  await page.$eval('#signup-email', el => el.setAttribute('value',"test@percy.io"));
  await page.$eval('#signup-submit', el => el.click());

  await percySnapshot(page, 'Signup Page Validation', {widths: TEST_WIDTHS});

  await page.goto(`${URL}/login`);

  await percySnapshot(page, 'Login Page', {widths: TEST_WIDTHS});

  await page.$eval('#login-email', el => el.setAttribute('value',"test-login@percy.io"));
  await page.$eval('#login-submit', el => el.click());

  await percySnapshot(page, 'Login Page Validation', {widths: TEST_WIDTHS});


  await page.goto(`${URL}/`);

  await percySnapshot(page, 'Index Page', {widths: TEST_WIDTHS});

  await page.$eval('#menu-toggle', el => el.click());

  await percySnapshot(page, 'Index Page Menu Closed', {widths: TEST_WIDTHS});

  // reset menu
  await page.$eval('#menu-toggle', el => el.click());

  await page.$eval('#messages-toggle', el => el.click());
  await page.$eval('#todo-toggle', el => el.click());
  await page.$eval('#calendar-toggle', el => el.click());

  await percySnapshot(page, 'Index Top Row Collapsed', {widths: TEST_WIDTHS});

  // reset page
  await page.$eval('#messages-toggle', el => el.click());
  await page.$eval('#todo-toggle', el => el.click());
  await page.$eval('#calendar-toggle', el => el.click());

  await page.click('#nav-profile-menu');

  await percySnapshot(page, 'Profile Menu', {widths: TEST_WIDTHS});

  // reset Page
  await page.click('#nav-profile-menu');

  await page.click('#nav-messages-menu');

  await percySnapshot(page, 'Messages Menu', {widths: TEST_WIDTHS});

  // reset page
  await page.click('#nav-messages-menu');

  await page.click('#nav-tasks-menu');

  await percySnapshot(page, 'Tasks Menu', {widths: TEST_WIDTHS});

  await page.goto(`${URL}/404_error`);

  await percySnapshot(page, '404 Page', {widths: TEST_WIDTHS});

  await page.goto(`${URL}/500_error`);

  await percySnapshot(page, '500 Page', {widths: TEST_WIDTHS});

  // Close up our Puppeteer browser.
  browser.close()

  // Shut down our HTTP server.
  server.close()
})()