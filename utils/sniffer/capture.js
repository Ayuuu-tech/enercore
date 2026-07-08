const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

(async () => {
  console.log("Launching browser...");
  const browser = await puppeteer.launch({
    headless: false,
    defaultViewport: null,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  const page = await browser.newPage();
  const capturedRequests = [];
  const outputPath = path.join(__dirname, 'trackso_captured.json');

  page.on('response', async (response) => {
    const url = response.url();
    // Capture only API calls to trackso
    if (url.includes('trackso.in') && !url.endsWith('.js') && !url.endsWith('.png') && !url.endsWith('.css')) {
      const request = response.request();
      const method = request.method();
      const status = response.status();
      
      let responseBody = null;
      if (status === 200) {
        try {
          responseBody = await response.json();
        } catch (e) {
          try {
            responseBody = await response.text();
          } catch (err) {}
        }
      }
      
      const item = {
        timestamp: new Date().toISOString(),
        url,
        method,
        status,
        requestHeaders: request.headers(),
        postData: request.postData(),
        responseBody
      };
      
      console.log(`[CAPTURED] ${method} - ${url} (Status: ${status})`);
      capturedRequests.push(item);
      fs.writeFileSync(outputPath, JSON.stringify(capturedRequests, null, 2));
    }
  });

  await page.goto('https://solar.trackso.in/login');
  console.log("\n==================================================================");
  console.log("👉 BROWSER OPENED! Please login to your Trackso account.");
  console.log("👉 Go to your plants dashboard and let it load the live data.");
  console.log(`👉 Captured logs are saving in real-time to: ${outputPath}`);
  console.log("👉 Once you see all data loaded, you can close the browser window.");
  console.log("==================================================================\n");
  
  // Wait for browser to be closed by user
  browser.on('disconnected', () => {
    console.log("Browser closed. Data saved successfully!");
    process.exit(0);
  });
})();
