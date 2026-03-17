const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  
  console.log('Testing Playwright browser automation...');
  await page.goto('https://example.com');
  const title = await page.title();
  console.log(`Page title: ${title}`);
  
  await browser.close();
  console.log('Playwright test complete!');
})();
