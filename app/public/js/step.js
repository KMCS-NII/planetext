(function() {
  var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  $(function() {
    var $attr, $dragged, $inserted_row, $instance, $tag, $value, $word, delete_inserted_row, drag_mode, dragged_element_original_text, dragged_selector, drop_ok, fill_instances_by_word, get_selector, insert_row_timer, num_selects, original_column, select_li, selects;
    $tag = $('#tag');
    $attr = $('#attr');
    $word = $('#word');
    $value = $('#value');
    $instance = $('#instance');
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
    $tag.on('update', function(evt, selected_tag) {
      var attr, attr_name, data, known, str, _ref, _results;
      $attr.empty();
      $word.empty();
      $value.empty();
      $instance.empty();
      if (selected_tag) {
        known = {};
        _ref = unknowns[selected_tag];
        _results = [];
        for (attr_name in _ref) {
          attr = _ref[attr_name];
          if (attr_name !== '') {
            $('<li draggable="true">').text(attr_name).appendTo($attr);
          }
          _results.push((function() {
            var _i, _len, _ref1, _results1;
            _ref1 = attr[1];
            _results1 = [];
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
              data = _ref1[_i];
              str = "" + data[2] + " (" + data[0] + "-" + data[1] + ")";
              if (!known[str]) {
                $('<li>').text(str).appendTo($instance);
                _results1.push(known[str] = true);
              } else {
                _results1.push(void 0);
              }
            }
            return _results1;
          })());
        }
        return _results;
      }
    });
    $tag.on('click', function() {
      $tag.find('li.selected').removeClass('selected');
      return $tag.trigger('update');
    });
    $tag.on('click', 'li', function(evt) {
      var $selected_li, selected_tag;
      evt.stopPropagation();
      $selected_li = select_li(evt);
      selected_tag = $selected_li.text();
      return $tag.trigger('update', selected_tag);
    });
    $attr.on('click', function() {
      $attr.find('li.selected').removeClass('selected');
      $word.empty();
      $value.empty();
      return $instance.empty();
    });
    $attr.on('click', 'li', function(evt) {
      var $selected_li, attr, attr_word, data, index, known, selected_attr, selected_tag, str, _results;
      evt.stopPropagation();
      $word.empty();
      $value.empty();
      $instance.empty();
      $selected_li = select_li(evt);
      selected_tag = $tag.find('li.selected').text();
      selected_attr = $selected_li.text();
      attr = unknowns[selected_tag][selected_attr];
      known = {};
      _results = [];
      for (attr_word in attr[0]) {
        $('<li draggable="true">').text(attr_word).appendTo($word);
        _results.push((function() {
          var _i, _len, _ref, _results1;
          _ref = attr[0][attr_word];
          _results1 = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            index = _ref[_i];
            data = attr[1][index];
            str = "" + data[2] + " (" + data[0] + "-" + data[1] + ")";
            if (!known[str]) {
              $('<li>').text(str).appendTo($instance);
              _results1.push(known[str] = true);
            } else {
              _results1.push(void 0);
            }
          }
          return _results1;
        })());
      }
      return _results;
    });
    $word.on('click', function() {
      $word.find('li.selected').removeClass('selected');
      $value.empty();
      return $instance.empty();
    });
    $word.on('click', 'li', function(evt) {
      var $selected_li, unique_values, value, _i, _len, _ref, _results;
      evt.stopPropagation();
      $value.empty();
      $instance.empty();
      $selected_li = select_li(evt);
      unique_values = fill_instances_by_word();
      _ref = Object.keys(unique_values);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        value = _ref[_i];
        _results.push($('<li>').text(value).appendTo($value));
      }
      return _results;
    });
    $value.on('click', function() {
      $value.find('li.selected').removeClass('selected');
      $instance.empty();
      return fill_instances_by_word();
    });
    $value.on('click', 'li', function(evt) {
      var $selected_li, attr, data, known, selected_attr, selected_tag, selected_value, str, _i, _len, _ref, _results;
      evt.stopPropagation();
      $instance.empty();
      $selected_li = select_li(evt);
      selected_tag = $tag.find('li.selected').text();
      selected_attr = $attr.find('li.selected').text();
      selected_value = $selected_li.text();
      attr = unknowns[selected_tag][selected_attr];
      known = {};
      _ref = attr[1];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        data = _ref[_i];
        if (data[3] === selected_value) {
          str = "" + data[2] + " (" + data[0] + "-" + data[1] + ")";
          if (!known[str]) {
            $('<li>').text(str).appendTo($instance);
            _results.push(known[str] = true);
          } else {
            _results.push(void 0);
          }
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    });
    $instance.on('click', function() {
      return $instance.find('li.selected').removeClass('selected');
    });
    $instance.on('click', 'li', function(evt) {
      var $selected_li;
      evt.stopPropagation();
      return $selected_li = select_li(evt);
    });
    selects = ['tag', 'attr', 'word', 'value', 'instance', 'independent', 'decoration', 'object', 'metainfo'];
    num_selects = selects.length;
    $('.selects ul').keydown(function(evt) {
      var $li, $selected_li, $ul, current, li, next, pos, ul, ul_bottom, ul_top;
      current = selects.indexOf(evt.target.id);
      next = (function() {
        switch (evt.keyCode) {
          case 37:
            return selects[(current + num_selects - 1) % num_selects];
          case 39:
            return selects[(current + 1) % num_selects];
          case 38:
            $selected_li = $(evt.target).find('li.selected');
            $li = $selected_li.prev();
            return selects[current];
          case 40:
            $selected_li = $(evt.target).find('li.selected');
            $li = $selected_li.next();
            return selects[current];
        }
      })();
      if (next) {
        evt.stopPropagation();
        evt.preventDefault();
        if ($selected_li) {
          if ((li = $li[0])) {
            $selected_li.removeClass('selected');
            $li.addClass('selected');
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
        return "" + selected_tag + "[" + selected_attr + ": " + (selected_words.get().join(' ')) + "]";
      } else if (selected_attr.length) {
        return "" + selected_tag + "[" + selected_attr + "]";
      } else {
        return selected_tag;
      }
    };
    window.parse_selector = function(selector) {
      var attr, data, matches, tag, vals, _;
      matches = /^([^\]\[]+)(?:\[([^:]*)(?::\s*([^\]]*))?\])?$/.exec(selector);
      _ = matches[0], tag = matches[1], attr = matches[2], vals = matches[3];
      data = [tag];
      if (attr) {
        data.push(attr);
      }
      if (vals) {
        data.push.apply(data, vals.split(/\s+/));
      }
      return data;
    };
    dragged_element_original_text = null;
    insert_row_timer = null;
    $inserted_row = $();
    $dragged = null;
    drop_ok = false;
    dragged_selector = null;
    original_column = null;
    drag_mode = null;
    delete_inserted_row = function() {
      $inserted_row.remove();
      return $inserted_row = $();
    };
    $('#tag, #attr, #word').on('dragstart', 'li', function(evt) {
      $('#independent, #decoration, #object, #metainfo').addClass('droppable');
      drop_ok = false;
      original_column = null;
      evt.target.click();
      $dragged = $(evt.target);
      dragged_element_original_text = $dragged.text();
      dragged_selector = get_selector();
      return $dragged.text(dragged_selector);
    });
    $('#independent, #decoration, #object, #metainfo').on('dragstart', 'li', function(evt) {
      drop_ok = false;
      $dragged = $(evt.target);
      original_column = $dragged.closest('ul').prop('id');
      dragged_selector = $dragged.text();
      return $("#tag, #attr, #values, #independent, #decoration, #object, #metainfo").addClass('droppable');
    });
    $('.selects').on('drag', 'li', function(evt) {
      if (dragged_element_original_text) {
        $dragged = $(evt.target);
        $dragged.text(dragged_element_original_text);
        return dragged_element_original_text = null;
      }
    });
    $('.selects').on('dragover', '.droppable, .droppable li', function(evt) {
      return evt.preventDefault();
    });
    $('.selects').on('dragenter', 'li:not(.inserted)', function(evt) {
      if ($(evt.target).closest('.selects').hasClass('untagged')) {
        return;
      }
      clearTimeout(insert_row_timer);
      return insert_row_timer = setTimeout((function() {
        delete_inserted_row();
        return $inserted_row = $('<li class="inserted">&nbsp;</li>').insertBefore(evt.target);
      }), 500);
    });
    $('.selects').on('dragleave', '.inserted', function(evt) {
      delete_inserted_row();
      clearTimeout(insert_row_timer);
      return insert_row_timer = null;
    });
    $('.selects').on('drop', '.droppable li, .droppable', function(evt) {
      var $target, $ul, pos, target_column, target_tagged;
      evt.preventDefault();
      evt.stopPropagation();
      drop_ok = true;
      $target = $(evt.target);
      $ul = $target.closest('ul');
      if (original_column) {
        $dragged.remove();
      }
      target_column = $ul.prop('id');
      target_tagged = $ul.closest('.selects').hasClass('tagged');
      if (target_tagged) {
        if (!$target.hasClass('inserted')) {
          delete_inserted_row();
          $inserted_row = $('<li class="inserted"></li>').appendTo($ul);
        }
        $inserted_row.text(dragged_selector);
      } else {
        target_column = null;
      }
      $inserted_row = $();
      pos = $target.hasClass('inserted') ? $target.index() : -1;
      $.post(dataset_url + '/step', {
        previous: original_column,
        column: target_column,
        pos: pos,
        selector: dragged_selector
      }, (function() {
        return location.reload(true);
      }));
      return original_column = null;
    });
    return $('.selects').on('dragend', function(evt) {
      $('.droppable').removeClass('droppable');
      if (!drop_ok) {
        delete_inserted_row();
      }
      return clearTimeout(insert_row_timer);
    });
  });

}).call(this);
