'use strict';
const { app, BrowserWindow, shell, session, ipcMain } = require('electron');
const path = require('node:path');
const fs = require('node:fs');
const APP_URL = "https://studytimer.ajdapp.org";
const BASE = new URL(APP_URL);
let win;
function onlyExternalHttps(raw) {
  try {
    const u = new URL(raw);
    if (u.protocol === 'https:' && u.origin !== BASE.origin) shell.openExternal(u.toString());
  } catch (_) {}
}

const INTRO_MARKER = path.join(app.getPath('userData'), 'intro-seen-v2');
function startBrandedApp(win) {
  const first=!fs.existsSync(INTRO_MARKER);
  return win.loadFile(path.join(__dirname,'intro.html'),{query:{first:first?'1':'0'}});
}
ipcMain.on('ajd:intro-done',(event,remember) => {
  if(!event.senderFrame || !event.senderFrame.url.startsWith('file://'))return;
  const current=BrowserWindow.fromWebContents(event.sender);
  if(!current || current.isDestroyed())return;
  if(remember === true) {
    try {fs.mkdirSync(path.dirname(INTRO_MARKER),{recursive:true});fs.writeFileSync(INTRO_MARKER,'1');}catch(_) {}
  }
  current.loadURL(APP_URL);
});
function createWindow() {
  win = new BrowserWindow({
    width: 1180, height: 840, minWidth: 850, minHeight: 670,
    show: false,
    icon: path.join(__dirname,'icon.png'), autoHideMenuBar: true,
    title: "Study Timer",
    backgroundColor: '#f7f4ec',
    webPreferences: {
      preload: path.join(__dirname,'preload.cjs'),
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
  startBrandedApp(win);
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
