const { chromium } = require('playwright');

(async () => {
  console.log('Setting up Google Alerts for neurovascular keywords...');
  
  // Connect to existing Chrome instance
  const browser = await chromium.connectOverCDP('http://localhost:9222').catch(async () => {
    // If no existing browser, launch new one
    return await chromium.launch({ 
      headless: false,
      args: ['--start-maximized']
    });
  });
  
  const context = await browser.newContext();
  const page = await context.newPage();
  
  // Navigate to Google Alerts
  await page.goto('https://www.google.com/alerts');
  await page.waitForTimeout(3000);
  
  console.log('On Google Alerts page');
  
  // List of high-priority alerts to create
  const alerts = [
    { query: '"mechanical thrombectomy" FDA approval', frequency: 'as-it-happens' },
    { query: '"neurovascular robotics" OR "endovascular robotics"', frequency: 'daily' },
    { query: '"stroke AI" OR "AI stroke diagnosis" clinical trial', frequency: 'daily' },
    { query: 'Penumbra OR Stryker OR Medtronic "new device" neurovascular', frequency: 'daily' },
    { query: 'XCath OR "Rapid Medical" robotic neurovascular', frequency: 'as-it-happens' },
    { query: '"neurovascular devices market" forecast 2026', frequency: 'weekly' },
    { query: 'thrombectomy "clinical trial results" 2026', frequency: 'daily' },
    { query: '"aneurysm treatment" "new technology" OR "new device"', frequency: 'weekly' },
    { query: '"flow diverter" FDA approval OR CE mark', frequency: 'daily' },
    { query: 'neurovascular patent filing AI robotics', frequency: 'weekly' }
  ];
  
  console.log(`Creating ${alerts.length} alerts...`);
  
  for (const alert of alerts) {
    try {
      // Find and fill the search box
      const searchBox = await page.locator('input[name="q"]').first();
      await searchBox.fill(alert.query);
      await page.waitForTimeout(1000);
      
      // Click "Create Alert" or show options
      const createButton = await page.locator('text=Create Alert').first();
      if (await createButton.isVisible().catch(() => false)) {
        await createButton.click();
      } else {
        // Click to show options first
        const optionsLink = await page.locator('text=Show options').first();
        if (await optionsLink.isVisible().catch(() => false)) {
          await optionsLink.click();
          await page.waitForTimeout(1000);
        }
        
        // Set frequency
        const freqDropdown = await page.locator('select').filter({ hasText: /as-it-happens|daily|weekly/ }).first();
        if (await freqDropdown.isVisible().catch(() => false)) {
          await freqDropdown.selectOption(alert.frequency);
        }
        
        // Click create
        await createButton.click();
      }
      
      await page.waitForTimeout(2000);
      console.log(`✅ Created alert: ${alert.query}`);
      
    } catch (err) {
      console.log(`⚠️  Could not create alert: ${alert.query} - ${err.message}`);
    }
  }
  
  console.log('\\n✅ Google Alerts setup complete!');
  console.log('You will receive email notifications for these keywords.');
  
  // Keep browser open for verification
  await page.waitForTimeout(10000);
  
})().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
