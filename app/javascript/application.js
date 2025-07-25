// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

// COPY PASTE
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import("@rails/ujs").start()
import("turbolinks").start()
import("@rails/activestorage").start()
import("channels")

import("custom.js")

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)
import 'bootstrap/dist/js/bootstrap'
import 'bootstrap/dist/css/bootstrap'

import $ from 'jquery';
import jQuery from 'jquery';
global.$ = jQuery;
global.jQuery = jQuery;