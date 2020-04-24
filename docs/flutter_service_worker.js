'use strict';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "index.html": "11dd07d0f2425974dc8738623c060c21",
"/": "11dd07d0f2425974dc8738623c060c21",
"main.dart.js": "418ddba491624ee85d758ad24888e095",
"favicon.png": "cca3b18e0159c429cb1e24b95fbc1e7c",
"icons/Icon-192.png": "60408552e687700e10027e9d94e4cb0a",
"icons/Icon-512.png": "f218436f277a931f812f4cef8c318c97",
"manifest.json": "9378a1fbc92cdaf0ae3de1f4ba01057c",
"assets/LICENSE": "9ffdd03a4c13dfec7ab5b903de5b3b20",
"assets/AssetManifest.json": "e26ab0f0a9ebee8025260de29a88a4ca",
"assets/FontManifest.json": "5fa2baa1355ee1ffd882bec6ab6780c7",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "2aa350bd2aeab88b601a593f793734c0",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "2bca5ec802e40d3f4b60343e346cedde",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "5a37ae808cf9f652198acde612b5328d",
"assets/fonts/MaterialIcons-Regular.ttf": "56d3ffdef7a25659eab6a68a3fbfaf16"
};

self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys().then(function (cacheName) {
      return caches.delete(cacheName);
    }).then(function (_) {
      return caches.open(CACHE_NAME);
    }).then(function (cache) {
      return cache.addAll(Object.keys(RESOURCES));
    })
  );
});

self.addEventListener('fetch', function (event) {
  event.respondWith(
    caches.match(event.request)
      .then(function (response) {
        if (response) {
          return response;
        }
        return fetch(event.request);
      })
  );
});
