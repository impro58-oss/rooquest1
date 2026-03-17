const { chromium } = require('playwright');

(async () => {
  console.log('Connecting to Polymarket portfolio...');
  
  const browser = await chromium.launch({ 
    headless: false,
    args: ['--start-maximized']
  });
  
  const context = await browser.newContext();
  const page = await context.newPage();
  
  // Navigate to Polymarket portfolio
  await page.goto('https://polymarket.com/portfolio');
  
  console.log('Waiting for page to load...');
  await page.waitForTimeout(5000);
  
  // Take screenshot
  await page.screenshot({ path: 'C:\\Users\\impro\\.openclaw\\workspace\\polymarket_portfolio.png', fullPage: true });
  console.log('Screenshot saved');
  
  // Get page content
  const content = await page.content();
  console.log('Page loaded. Content length:', content.length);
  
  // Keep browser open for 2 minutes
  await page.waitForTimeout(120000);
  await browser.close();
})();
