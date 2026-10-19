package com.yodlx.apk;

import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

public class MainActivity extends android.app.Activity {

    private static final String SITE_URL = "https://ai.yodlx.com/";
    private static final String SPLASH_ASSET = "file:///android_asset/splash.html";
    private WebView browser;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Window w = getWindow();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            w.setStatusBarColor(Color.TRANSPARENT);
            w.setNavigationBarColor(Color.TRANSPARENT);
        }

        FrameLayout root = new FrameLayout(this);
        browser = new WebView(this);
        root.addView(browser, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));
        setContentView(root);

        WebSettings s = browser.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        s.setGeolocationEnabled(false);
        s.setAllowFileAccess(true);
        s.setAllowContentAccess(true);
        s.setAllowFileAccessFromFileURLs(true);
        s.setAllowUniversalAccessFromFileURLs(true);
        s.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
        s.setCacheMode(WebSettings.LOAD_DEFAULT);
        s.setUseWideViewPort(true);
        s.setBuiltInZoomControls(false);
        s.setDisplayZoomControls(false);
        s.setTextZoom(100);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            s.setForceDark(WebSettings.FORCE_DARK_OFF);
        }

        browser.addJavascriptInterface(new WebAppBridge(), "android");

        browser.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                if (url.startsWith("file:///android_asset/")) {
                    return false;
                }
                if (url.startsWith(SITE_URL) || url.startsWith("https://ai.yodlx.com")) {
                    return false;
                }
                android.content.Intent i = new android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(url));
                try { startActivity(i); } catch (android.content.ActivityNotFoundException e) { }
                return true;
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                // page load can reset system ui flags; re-apply immersive
                applyImmersive();
            }

            @Override
            public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
                if (!SITE_URL.equals(view.getUrl())) {
                    view.loadUrl(SITE_URL);
                }
            }
        });

        browser.setWebChromeClient(new android.webkit.WebChromeClient());

        // robust immersive: apply now + re-apply on focus + after layout
        applyImmersive();
        getWindow().getDecorView().setOnSystemUiVisibilityChangeListener(new View.OnSystemUiVisibilityChangeListener() {
            @Override
            public void onSystemUiVisibilityChange(int visibility) {
                applyImmersive();
            }
        });
        browser.post(new Runnable() {
            @Override
            public void run() {
                applyImmersive();
            }
        });

        browser.loadUrl(SPLASH_ASSET);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) applyImmersive();
    }

    private void applyImmersive() {
        int flags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            getWindow().getDecorView().setSystemUiVisibility(flags);
        }
        // API 23+: WindowInsetsController is more reliable than decor flags alone
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                android.view.WindowInsetsController ic = getWindow().getInsetsController();
                if (ic != null) {
                    ic.hide(android.view.WindowInsets.Type.statusBars()
                            | android.view.WindowInsets.Type.navigationBars());
                    ic.setSystemBarsAppearance(0, 0);
                }
            } catch (Exception e) { /* ignore, flags path remains */ }
        }
    }

    @Override
    public void onDestroy() {
        if (browser != null) { browser.destroy(); }
        super.onDestroy();
    }

    @Override
    public void onTrimMemory(int level) {
        super.onTrimMemory(level);
        if (browser != null && level >= android.content.ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW) {
            browser.clearCache(true);
        }
    }

    private class WebAppBridge {
        @JavascriptInterface
        void goToSite(String url) {
            run(() -> {
                if (browser != null && url != null && !url.isEmpty()) {
                    browser.clearHistory();
                    browser.loadUrl(url);
                }
            });
        }
    }

    private void run(Runnable r) {
        if (android.os.Looper.myLooper() == android.os.Looper.getMainLooper()) {
            r.run();
        } else {
            new android.os.Handler(android.os.Looper.getMainLooper()).post(r);
        }
    }
}