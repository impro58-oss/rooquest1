const { chromium } = require('playwright');

(async () => {
  console.log('Launching visible browser...');
  
  const browser = await chromium.launch({ 
    headless: false,
    args: ['--start-maximized']
  });
  
  const page = await browser.newPage();
  await page.goto('https://polymarket.com');
  
  console.log('✅ Browser open at Polymarket.com');
  console.log('⏳ Keeping browser alive for 5 minutes...');
  console.log('🖱️  You can log in manually now');
  
  // Wait 5 minutes
  await page.waitForTimeout(300000);
  
  console.log('Closing browser...');
  await browser.close();
})().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
