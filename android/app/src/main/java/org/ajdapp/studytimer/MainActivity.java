package org.ajdapp.studytimer;

import android.app.Activity;
import android.app.PictureInPictureParams;
import android.content.Intent;
import android.content.res.Configuration;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Rational;
import android.view.View;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import org.json.JSONTokener;

/** Secure website shell with a native Android Picture-in-Picture countdown. */
public class MainActivity extends Activity {
    private static final String HOME = "https://studytimer.ajdapp.org/";
    private static final String HOST = "studytimer.ajdapp.org";
    private final Handler handler = new Handler(Looper.getMainLooper());
    private WebView browser;
    private TimerView pip;
    private long endMs = 0;
    private boolean timerRunning = false;
    private String mode = "focus";
    private boolean inPip = false;
    private boolean pageReady = false;

    private final Runnable tick = new Runnable() {
        @Override public void run() {
            if (browser != null && pageReady) {
                browser.evaluateJavascript(
                    "(function(){try{document.dispatchEvent(new Event('visibilitychange'));var t=JSON.parse(localStorage.getItem('study-tracker-clock')||'{}');return (t.running?'1':'0')+'|'+(Number(t.ends)||0)+'|'+(t.mode||'focus')}catch(e){return '0|0|focus'}})()",
                    value -> { try {
                        Object v = new JSONTokener(value).nextValue();
                        String[] fields = String.valueOf(v).split("\\|", 3);
                        if (fields.length == 3) {
                            timerRunning = "1".equals(fields[0]);
                            endMs = timerRunning ? Long.parseLong(fields[1]) : 0;
                            mode = "break".equals(fields[2]) ? "break" : "focus";
                            updatePictureInPictureParams();
                        }
                    } catch (Exception ignored) {} }
                );
            }
            if (pip != null) {
                long remaining = timerRunning ? Math.max(0, endMs - System.currentTimeMillis()) : 0;
                pip.setState(mode, (remaining + 999L) / 1000L);
            }
            handler.postDelayed(this, 1000L);
        }
    };

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        FrameLayout root = new FrameLayout(this);
        browser = new WebView(this);
        browser.getSettings().setJavaScriptEnabled(true);
        browser.getSettings().setDomStorageEnabled(true);
        browser.getSettings().setMediaPlaybackRequiresUserGesture(false);
        browser.setWebChromeClient(new WebChromeClient());
        browser.setWebViewClient(new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                return request.isForMainFrame() && route(request.getUrl());
            }
            @Override public boolean shouldOverrideUrlLoading(WebView view, String url) {
                return route(Uri.parse(url));
            }
            @Override public void onPageFinished(WebView view, String url) {
                Uri u = Uri.parse(url);
                pageReady = "https".equalsIgnoreCase(u.getScheme()) && HOST.equalsIgnoreCase(u.getHost());
                if (pageReady) view.evaluateJavascript("window.AJDNativePiP=true", null);
            }
        });
        root.addView(browser, new FrameLayout.LayoutParams(-1, -1));
        pip = new TimerView();
        pip.setVisibility(View.GONE);
        root.addView(pip, new FrameLayout.LayoutParams(-1, -1));
        setContentView(root);
        browser.loadUrl(HOME);
        handler.post(tick);
    }

    private boolean route(Uri u) {
        if ("ajdstudytimer".equalsIgnoreCase(u.getScheme())) {
            Uri current = Uri.parse(browser.getUrl() == null ? "" : browser.getUrl());
            if ("pip".equals(u.getHost()) && "https".equals(current.getScheme()) && HOST.equals(current.getHost())) {
                try {
                    long requestedEnd = Long.parseLong(u.getQueryParameter("ends"));
                    long remaining = requestedEnd - System.currentTimeMillis();
                    if (remaining > 0 && remaining <= 86400000L &&
                        getPackageManager().hasSystemFeature(android.content.pm.PackageManager.FEATURE_PICTURE_IN_PICTURE)) {
                        endMs = requestedEnd; timerRunning = true;
                        mode = "break".equals(u.getQueryParameter("mode")) ? "break" : "focus";
                        pip.setState(mode, (remaining + 999L) / 1000L);
                        updatePictureInPictureParams();
                        enterPictureInPictureMode(new PictureInPictureParams.Builder().setAspectRatio(new Rational(10,6)).build());
                    } else android.widget.Toast.makeText(this,"PiP requires a running timer and device support.",android.widget.Toast.LENGTH_LONG).show();
                } catch (Exception e) { android.widget.Toast.makeText(this,"Unable to open PiP. Check Picture-in-Picture permission in Android Settings.",android.widget.Toast.LENGTH_LONG).show(); }
            }
            return true;
        }
        if ("https".equalsIgnoreCase(u.getScheme()) && HOST.equalsIgnoreCase(u.getHost())) return false;
        if ("https".equalsIgnoreCase(u.getScheme())) {
            try { startActivity(new Intent(Intent.ACTION_VIEW, u)); } catch (Exception ignored) {}
        }
        return true;  // Never load untrusted top-level origins or intent:// in privileged webview.
    }

    private void updatePictureInPictureParams() {
        if (Build.VERSION.SDK_INT < 26) return;
        PictureInPictureParams.Builder b = new PictureInPictureParams.Builder()
            .setAspectRatio(new Rational(10, 6));
        if (Build.VERSION.SDK_INT >= 31) b.setAutoEnterEnabled(timerRunning);
        try { setPictureInPictureParams(b.build()); } catch (Exception ignored) {}
    }

    @Override protected void onUserLeaveHint() {
        super.onUserLeaveHint();
        if (Build.VERSION.SDK_INT >= 26 && Build.VERSION.SDK_INT < 31 && timerRunning) {
            try { enterPictureInPictureMode(new PictureInPictureParams.Builder().setAspectRatio(new Rational(10, 6)).build()); } catch (Exception ignored) {}
        }
    }

    @Override public void onPictureInPictureModeChanged(boolean isInPictureInPictureMode, Configuration configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, configuration);
        inPip = isInPictureInPictureMode;
        browser.setVisibility(inPip ? View.INVISIBLE : View.VISIBLE);
        pip.setVisibility(inPip ? View.VISIBLE : View.GONE);
    }

    @Override public void onBackPressed() {
        if (browser != null && browser.canGoBack()) browser.goBack();
        else super.onBackPressed();
    }

    @Override protected void onDestroy() {
        handler.removeCallbacksAndMessages(null);
        if (browser != null) {
            browser.stopLoading();
            browser.destroy();
            browser = null;
        }
        super.onDestroy();
    }

    private final class TimerView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private long seconds = 0;
        private String displayMode = "focus";

        TimerView() { super(MainActivity.this); setLayerType(View.LAYER_TYPE_SOFTWARE, null); }
        void setState(String m, long s) {
            displayMode = m; seconds = s; invalidate();
        }
        @Override protected void onDraw(Canvas c) {
            super.onDraw(c);
            float w=getWidth(), h=getHeight();
            c.drawColor(Color.rgb(31,25,49));
            paint.setColor(Color.rgb(252,207,231));
            paint.setTextAlign(Paint.Align.CENTER);
            paint.setTypeface(android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.BOLD));
            paint.setTextSize(h*.33f);
            String txt=String.format(java.util.Locale.US,"%02d:%02d",seconds/60,seconds%60);
            c.drawText(txt, w/2, h*.53f, paint);
            paint.setTextSize(h*.12f);
            paint.setColor(Color.rgb(237,231,252));
            c.drawText("break".equals(displayMode) ? "☕ BREAK TIME" : "STUDY TIME",w/2,h*.76f,paint);
        }
    }
}
