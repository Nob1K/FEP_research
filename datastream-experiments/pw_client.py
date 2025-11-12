import time, random, json
from playwright.sync_api import sync_playwright

CLIENT_PROXY = "http://127.0.0.1:31000"

SITES = [
    "https://www.google.com"
]

def log(string):
    with open("client.txt", "w") as f:
        f.write(string)


def pause(min_s=0.4, max_s=1.2):
    time.sleep(random.uniform(min_s, max_s))

def stealth_init_script():
    return """
    Object.defineProperty(navigator, 'webdriver', {get: () => false});
    Object.defineProperty(navigator, 'languages', {get: () => ['en-US', 'en']});
    Object.defineProperty(navigator, 'plugins', {get: () => [1,2,3]});
    """

def visit(url, page):
    page.goto(url, timeout=30000, wait_until='load')
    pause(0.6, 1.2)

    page.mouse.wheel(0, 300)
    pause(0.1, 0.3)
    page.mouse.wheel(0, -100)
    pause(0.2, 0.6)

if __name__ == "__main__":
    
    results = []
    viewport = {"width": random.choice([1200, 1280, 1366]),
                "height": random.choice([720, 768, 800])}
    
    with sync_playwright() as pw:
        browser = pw.chromium.launch(
            headless=True,
            proxy={"server": CLIENT_PROXY},
            args=[
                "--no-sandbox",
                "--disable-setuid-sandbox",
                "--disable-dev-shm-usage",
                "--disable-blink-features=AutomationControlled" 
            ]
        )
        
        try:
            context = browser.new_context(
                    viewport=viewport,
                    user_agent=("Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                                "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36")
                )
            context.add_init_script(stealth_init_script())
            page = context.new_page()
            
            for url in SITES:
                try:
                    visit(url, page)
                    log(f"sucessful visit to {url}\n")
                    # results.append({"url": url, "status": "ok"})
                except Exception as e:
                    log(f"something went wrong when visiting {url}, error {str(e)}\n")
                    # results.append({"url": url, "status": "error", "error": str(e)})
            # with open("playwright_minimal_result.json", "w") as f:
            #     json.dump(results, f, indent=2)

            page.close()
            context.close()
            
        finally:
            browser.close()