/*!
 * Copyright (C) 2012, The SwitchyOmega Authors. Please see the AUTHORS file
 * for details.
 *
 * This file is part of SwitchyOmega.
 *
 * SwitchyOmega is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SwitchyOmega is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SwitchyOmega.  If not, see <http://www.gnu.org/licenses/>.
 */

(function () {
  'use strict';
  // Forbid direct view on this page
  if (window.top === window) {
    location.href = location.href.replace(".html", "_safe.html");
  }
  
  // Dart uses symbol $ in generated scripts.
  jQuery.noConflict();
  var $ = jQuery;
  
  var c = new Communicator(window.top);

  // Get memorized tabs
  var isDocReady = false;
  var showTabInner = function (hash) {
    $('#options-nav a[href="' + hash + '"]').tab('show');
  };
  var showTab = function (hash) {
    if (isDocReady) {
      showTabInner(hash);
    } else {
      $(document).ready(function () {
        showTabInner(hash);
      });
    }
  };

  var i18n = null;
  c.send('i18n.cache', null, function (cache) {
    i18n = new i18nDict(cache);
    var MutationObserver = window.MutationObserver ||
                           window.WebKitMutationObserver;
    var ob = new MutationObserver(function (mutations) {
      mutations.forEach(function (record) {
        switch (record.type) {
          case 'attributes':
            i18nTemplate.process(record.target, i18n);
            break;
          case 'childList':
            for (var i = 0; i < record.addedNodes.length; i++) {
		      if (record.addedNodes[i] instanceof Element) {
		        i18nTemplate.process(record.addedNodes[i], i18n);
		      }
            }
            break;
        }
      });
    });
    ob.observe(document, {
        childList: true,
        attributes: true,
        subtree: true
    });
    i18nTemplate.process(document, i18n);
  });
  
  c.on({
    'options.init': function () {
	  if (location.hash) {
	    showTab(location.hash);
	    location.hash = '';
	  } else {
	    c.send('tab.get', null, function (hash) {
	      if (hash) {
	        showTab(hash);
	      }
	    });
	  }
	}
  });

  $(document).ready(function () {
    isDocReady = true;
    // Sortable
    var containers = $('.cycle-profile-container');
    containers.sortable({
      connectWith: '.cycle-profile-container',
      change: function () {
        // onFieldModified(false);
      }
    }).disableSelection();
    var quickSwitch = $('#quick-switch');
    quickSwitch.change(function () {
      if (quickSwitch[0].checked) {
        containers.sortable('enable');
        $('#quick-switch-settings').slideDown();
      } else {
        containers.sortable('disable');
        $('#quick-switch-settings').slideUp();
      }
    });
    
    // Conditions Sort
    var conditions = $('.conditions');
    conditions.sortable({
      change: function () {
        // onFieldModified(false);
      }
    }).disableSelection();
    
    // Memorize Tab
    $('#options-nav').on('shown', 'a[data-toggle="tab"]', function (e) {
      var tabHash = e.target.getAttribute('href');
      c.send('tab.set', tabHash);
    });
    
    var fireChangeEvent = function (target) {
      var evt = document.createEvent('HTMLEvents');
      evt.initEvent('change', true, true);
      target.dispatchEvent(evt);
    };
    
    // Clear input
    $('body').on('click', '.clear-input', function (e) {
      var button = $(e.target).closest('.clear-input');
      var input = button.prev('input');
      if (button.hasClass('revert')) {
        input.val(input.attr('data-restore'));
        fireChangeEvent(input[0]);
        button.removeClass('revert');
        button.find('i').removeClass('icon-repeat').addClass('icon-remove');
      } else {
        var v = input.val();
        if (v) {
          input.attr('data-restore', v);
          input.val('');
          fireChangeEvent(input[0]);
          button.addClass('revert');
          button.find('i').removeClass('icon-remove').addClass('icon-repeat');
          var handler = function () {
            if (input.val()) {
              button.removeClass('revert');
              button.find('i').removeClass('icon-repeat').addClass('icon-remove');
              input.off(eventMap);
            }
          };
          var eventMap = {'change': handler, 'keyup': handler, 'keydown': handler};
          input.on(eventMap);
        }
      }
    });
  });

})();