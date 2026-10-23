'use strict';
const { app, BrowserWindow, shell, session } = require('electron');
const APP_URL = "https://studytimer.ajdapp.org";
const BASE = new URL(APP_URL);
let win;
function onlyExternalHttps(raw) {
  try {
    const u = new URL(raw);
    if (u.protocol === 'https:' && u.origin !== BASE.origin) shell.openExternal(u.toString());
  } catch (_) {}
}
function createWindow() {
  win = new BrowserWindow({
    width: 1180, height: 840, minWidth: 850, minHeight: 670,
    show: false, autoHideMenuBar: true,
    title: "Study Timer",
    backgroundColor: '#10192b',
    webPreferences: {
      nodeIntegration: false, contextIsolation: true, sandbox: true,
      webSecurity: true, allowRunningInsecureContent: false
    }
  });
  win.once('ready-to-show', () => win.show());
  win.webContents.setWindowOpenHandler(({ url }) => {
    onlyExternalHttps(url);
    return { action: 'deny' };
  });
  win.webContents.on('will-navigate', (event, url) => {
    try {
      const u = new URL(url);
      if (u.origin === BASE.origin && u.protocol === 'https:') return;
    } catch (_) {}
    event.preventDefault();
    onlyExternalHttps(url);
  });
  win.webContents.on('will-redirect', (event, url) => {
    try { if (new URL(url).origin === BASE.origin) return; } catch (_) {}
    event.preventDefault();
    onlyExternalHttps(url);
  });
  win.loadURL(APP_URL);
}
app.whenReady().then(() => {
  // Only the hosted application runs inside this shell; external destinations
  // open in the user's regular browser, never as privileged Electron content.
  session.defaultSession.setPermissionCheckHandler((_contents, permission, _origin) => {
    return ['notifications','fullscreen'].includes(permission);
  });
  session.defaultSession.setPermissionRequestHandler((contents, permission, callback, details) => {
    const requesting = details && details.requestingUrl || contents.getURL();
    let trusted = false;
    try { trusted = new URL(requesting).origin === BASE.origin; } catch (_) {}
    callback(trusted && ['notifications','fullscreen'].includes(permission));
  });
  createWindow();
  app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});
app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });
