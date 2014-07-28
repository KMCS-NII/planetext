(function() {
  var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  $(function() {
    var $attr, $instance, $tag, $value, $word, disable_empty, disable_if_empty, dragged_element_original_text, fill_instances_by_word, get_selector, select_li;
    disable_empty = function() {
      disable_if_empty($tag);
      disable_if_empty($attr);
      disable_if_empty($word);
      disable_if_empty($value);
      return disable_if_empty($instance);
    };
    disable_if_empty = function($select) {
      var empty;
      empty = $select.find('li').length === 0;
      return $select.toggleClass('disabled', empty);
    };
    select_li = function(evt) {
      var $selected_li;
      $(evt.target).closest('ul').find('li.selected').removeClass('selected');
      return $selected_li = $(evt.target).addClass('selected');
    };
    fill_instances_by_word = function() {
      var attr, data, index, matching, selected_attr, selected_tag, str, unique_values, _i, _len, _ref;
      matching = null;
      selected_tag = $tag.find('li.selected').text();
      selected_attr = $attr.find('li.selected').text();
      attr = unknowns[selected_tag][selected_attr];
      $word.find('li.selected').map(function() {
        var index, word, word_instances, _i, _len, _results, _results1;
        word = this.textContent;
        word_instances = attr[0][word];
        if (matching) {
          _results = [];
          for (index in matching) {
            if (__indexOf.call(word_instances, index) < 0) {
              _results.push(delete matching[index]);
            } else {
              _results.push(void 0);
            }
          }
          return _results;
        } else {
          matching = {};
          _results1 = [];
          for (_i = 0, _len = word_instances.length; _i < _len; _i++) {
            index = word_instances[_i];
            _results1.push(matching[index] = true);
          }
          return _results1;
        }
      });
      unique_values = {};
      _ref = Object.keys(matching);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        index = _ref[_i];
        data = attr[1][index];
        str = "" + data[2] + " (" + data[0] + "-" + data[1] + ")";
        $('<li>').text(str).appendTo($instance);
        unique_values[attr[1][index][3]] = true;
      }
      return unique_values;
    };
    $tag = $('#tag');
    $attr = $('#attr');
    $word = $('#word');
    $value = $('#value');
    $instance = $('#instance');
    $tag.click(function() {
      $tag.find('li.selected').removeClass('selected');
      $attr.empty();
      $word.empty();
      $value.empty();
      $instance.empty();
      return disable_empty();
    });
    $tag.on('click', 'li', function(evt) {
      var $selected_li, attr, attr_name, data, known, selected_tag, str, _i, _len, _ref, _ref1;
      evt.stopPropagation();
      $attr.empty();
      $word.empty();
      $value.empty();
      $instance.empty();
      if (evt.target.nodeName !== "LI") {
        return;
      }
      $selected_li = select_li(evt);
      selected_tag = $selected_li.text();
      known = {};
      _ref = unknowns[selected_tag];
      for (attr_name in _ref) {
        attr = _ref[attr_name];
        if (attr_name !== '') {
          $('<li draggable="true">').text(attr_name).appendTo($attr);
        }
        _ref1 = attr[1];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          data = _ref1[_i];
          str = "" + data[2] + " (" + data[0] + "-" + data[1] + ")";
          if (!known[str]) {
            $('<li>').text(str).appendTo($instance);
            known[str] = true;
          }
        }
      }
      return disable_empty();
    });
    $attr.click(function() {
      $attr.find('li.selected').removeClass('selected');
      $word.empty();
      $value.empty();
      $instance.empty();
      return disable_empty();
    });
    $attr.on('click', 'li', function(evt) {
      var $selected_li, attr, attr_word, data, index, known, selected_attr, selected_tag, str, _i, _len, _ref;
      evt.stopPropagation();
      $word.empty();
      $value.empty();
      $instance.empty();
      $selected_li = select_li(evt);
      selected_tag = $tag.find('li.selected').text();
      selected_attr = $selected_li.text();
      attr = unknowns[selected_tag][selected_attr];
      known = {};
      for (attr_word in attr[0]) {
        $('<li draggable="true">').text(attr_word).appendTo($word);
        _ref = attr[0][attr_word];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          index = _ref[_i];
          data = attr[1][index];
          str = "" + data[2] + " (" + data[0] + "-" + data[1] + ")";
          if (!known[str]) {
            $('<li>').text(str).appendTo($instance);
            known[str] = true;
          }
        }
      }
      return disable_empty();
    });
    $word.click(function() {
      $word.find('li.selected').removeClass('selected');
      $value.empty();
      $instance.empty();
      return disable_empty();
    });
    $word.on('click', 'li', function(evt) {
      var $selected_li, unique_values, value, _i, _len, _ref;
      evt.stopPropagation();
      $value.empty();
      $instance.empty();
      $selected_li = select_li(evt);
      unique_values = fill_instances_by_word();
      _ref = Object.keys(unique_values);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        value = _ref[_i];
        $('<li>').text(value).appendTo($value);
      }
      return disable_empty();
    });
    $value.click(function() {
      $value.find('li.selected').removeClass('selected');
      $instance.empty();
      fill_instances_by_word();
      return disable_empty();
    });
    $value.on('click', 'li', function(evt) {
      var $selected_li, attr, data, known, selected_attr, selected_tag, selected_value, str, _i, _len, _ref;
      evt.stopPropagation();
      $instance.empty();
      $selected_li = select_li(evt);
      selected_tag = $tag.find('li.selected').text();
      selected_attr = $attr.find('li.selected').text();
      selected_value = $selected_li.text();
      attr = unknowns[selected_tag][selected_attr];
      known = {};
      _ref = attr[1];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        data = _ref[_i];
        if (data[3] === selected_value) {
          str = "" + data[2] + " (" + data[0] + "-" + data[1] + ")";
          if (!known[str]) {
            $('<li>').text(str).appendTo($instance);
            known[str] = true;
          }
        }
      }
      return disable_empty();
    });
    $instance.click(function() {
      return $instance.find('li.selected').removeClass('selected');
    });
    $instance.on('click', 'li', function(evt) {
      var $selected_li;
      evt.stopPropagation();
      return $selected_li = select_li(evt);
    });
    $('.untagged ul').keydown(function(evt) {
      var $li, $selected_li, $ul, current, li, next, pos, selects, ul, ul_bottom, ul_top;
      selects = ['tag', 'attr', 'word', 'value', 'instance'];
      current = selects.indexOf(evt.target.id);
      next = (function() {
        switch (evt.keyCode) {
          case 37:
            return selects[current - 1];
          case 39:
            return selects[current + 1];
          case 38:
            $selected_li = $(evt.target).find('li.selected');
            $li = $selected_li.prev();
            if ($li.length) {
              $selected_li.removeClass('selected');
              $li.addClass('selected');
            }
            return selects[current];
          case 40:
            $selected_li = $(evt.target).find('li.selected');
            $li = $selected_li.next();
            if ($li.length) {
              $selected_li.removeClass('selected');
              $li.addClass('selected');
            }
            return selects[current];
        }
      })();
      if (next) {
        evt.stopPropagation();
        evt.preventDefault();
        if ($selected_li) {
          if ((li = $li[0])) {
            ul = evt.target;
            ul_top = ul.scrollTop;
            ul_bottom = ul_top + ul.clientHeight - li.clientHeight;
            pos = li.offsetTop - ul.offsetTop;
            if (pos < ul_top) {
              li.scrollIntoView(true);
            } else if (pos > ul_bottom) {
              li.scrollIntoView(false);
            }
          }
        } else {
          $ul = $("#" + next);
          if ($ul.hasClass('disabled')) {
            return;
          }
          $ul.focus();
          $li = $ul.find('li.selected');
          if (!$li.length) {
            $li = $ul.find('li:first-child');
          }
        }
        if ($li.length) {
          return $li[0].click();
        }
      }
    });
    get_selector = function() {
      var selected_attr, selected_tag, selected_words;
      selected_tag = $tag.find('li.selected').text();
      selected_attr = $attr.find('li.selected').text();
      selected_words = $word.find('li.selected').map(function() {
        return $(this).text();
      });
      if (selected_words.length) {
        console.log(selected_words);
        return "" + selected_tag + "[" + selected_attr + ": " + (selected_words.get().join(' ')) + "]";
      } else if (selected_attr) {
        return "" + selected_tag + "[" + selected_attr + "]";
      } else {
        return selected_tag;
      }
    };
    dragged_element_original_text = null;
    $('.untagged').on('dragstart', 'li', function(evt) {
      var $dragged, selector;
      evt.target.click();
      $dragged = $(evt.target);
      dragged_element_original_text = $dragged.text();
      selector = get_selector();
      return $dragged.text(selector);
    });
    $('.untagged').on('drag', 'li', function(evt) {
      var $dragged;
      if (dragged_element_original_text) {
        $dragged = $(evt.target);
        $dragged.text(dragged_element_original_text);
        return dragged_element_original_text = null;
      }
    });
    return disable_empty();
  });

}).call(this);
