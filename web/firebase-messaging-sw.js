// web/firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/10.9.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.9.0/firebase-messaging-compat.js');

firebase.initializeApp({
    apiKey: 'AIzaSyD_nySkaHxrvRkd5elV0qLN5HeFWC15cDo',
    appId: '1:80089306082:web:ccee7b65a332d5b1551fbb',
    messagingSenderId: '80089306082',
    projectId: 'padariavinhos-1f842',
    authDomain: 'padariavinhos-1f842.firebaseapp.com',
    databaseURL: 'https://padariavinhos-1f842-default-rtdb.firebaseio.com',
    storageBucket: 'padariavinhos-1f842.firebasestorage.app',
    measurementId: 'G-BWED7ETF50',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("📩 Mensagem recebida em background:", payload);
  self.registration.showNotification(payload.notification.title, {
    body: payload.notification.body,
  });
});