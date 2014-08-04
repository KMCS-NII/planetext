$ ->
  is_mac = window.navigator.platform == 'MacIntel'
  is_ctrl_down = (evt) -> if is_mac then evt.metaKey else evt.ctrlKey

  $tag = $('#tag')
  $attr = $('#attr')
  $word = $('#word')
  $value = $('#value')
  $instance = $('#instance')
  $selects = $('.selects')

  fill_instances_by_word = ->
    matching = null
    selected_tag = $tag.find('li.selected').text()
    selected_attr = $attr.find('li.selected').text()
    attr = unknowns[selected_tag][selected_attr]
    $word.find('li.selected').each ->
      word = this.textContent
      word_instances = attr[0][word]
      if matching
        for index of matching
          delete matching[index] unless parseInt(index, 10) in word_instances
      else
        matching = {}
        matching[index] = true for index in word_instances
    return {} unless matching
    unique_values = {}
    for index in Object.keys(matching)
      data = attr[1][index]
      str = "#{data[2]} (#{data[0]}-#{data[1]})"
      $('<li>').text(str).appendTo($instance)
      unique_values[attr[1][index][3]] = true
    unique_values

  $selects.on 'customselect', '.uniselect', (evt, params) ->
    $li = $(params.li)
    $li.closest('ul').find('li.selected').removeClass('selected')
    $li.addClass('selected')
  $selects.on 'customselect', '.multiselect', (evt, params) ->
    $li = $(params.li)
    $ul = $li.closest('ul')
    unless params.noselect
      $ul.find('li.selectcursor').removeClass('selectcursor')
      $li.addClass('selectcursor')
      if !params.ctrl
        $li.closest('ul').find('li.selected').removeClass('selected')
      selected = $li.hasClass('selected')
      if !selected
        $li.addClass('selected')
      else if params.ctrl
        $li.removeClass('selected')

  $selects.on 'click', '.uniselect, .multiselect', (evt) ->
    evt.stopPropagation()
    $ul = $(evt.target)
    $ul.find('li.selected').removeClass('selected')
    $ul.trigger('update')
  $selects.on 'click', '.uniselect > li, .multiselect > li', (evt) ->
    evt.stopPropagation()
    $ul = $(evt.target).closest('ul')
    $ul.trigger('customselect', { li: evt.target, ctrl: is_ctrl_down(evt) })
    $ul.trigger('update')

  $tag.on 'update', (evt) ->
    $attr.empty()
    $word.empty()
    $value.empty()
    $instance.empty()
    selected_tag = $tag.find('li.selected').text()
    if selected_tag
      known = {}
      for attr_name, attr of unknowns[selected_tag]
        unless attr_name == ''
          $('<li draggable="true">').text(attr_name).appendTo($attr)
        for data in attr[1]
          str = "#{data[2]} (#{data[0]}-#{data[1]})"
          unless known[str]
            $('<li>').text(str).appendTo($instance)
            known[str] = true

  $attr.on 'update', (evt) ->
    $word.empty()
    $value.empty()
    $instance.empty()
    selected_attr = $attr.find('li.selected').text()
    if selected_attr
      selected_tag = $tag.find('li.selected').text()
      attr = unknowns[selected_tag][selected_attr]
      known = {}
      for attr_word of attr[0]
        $('<li draggable="true">').text(attr_word).appendTo($word)
        for index in attr[0][attr_word]
          data = attr[1][index]
          str = "#{data[2]} (#{data[0]}-#{data[1]})"
          unless known[str]
            $('<li>').text(str).appendTo($instance)
            known[str] = true

  $word.on 'update', ->
    $value.empty()
    $instance.empty()
    unique_values = fill_instances_by_word()
    for value in Object.keys(unique_values)
      $('<li>').text(value).appendTo($value)

  $value.on 'update', ->
    $instance.empty()
    selected_value = $value.find('li.selected').text()
    if selected_value
      selected_tag = $tag.find('li.selected').text()
      selected_attr = $attr.find('li.selected').text()
      attr = unknowns[selected_tag][selected_attr]
      known = {}
      for data in attr[1]
        if data[3] == selected_value
          str = "#{data[2]} (#{data[0]}-#{data[1]})"
          unless known[str]
            $('<li>').text(str).appendTo($instance)
            known[str] = true
    fill_instances_by_word()

  $instance.on 'update', ->
    selected_instance = $instance.find('li.selected').text()
    if selected_instance
      # TODO show the instance
    else
      # TODO clear the instance

  selects = [
    'tag',
    'attr',
    'word',
    'value',
    'instance',
    'independent',
    'decoration',
    'object',
    'metainfo'
  ]
  num_selects = selects.length
  $('.selects ul').on 'keydown', (evt) ->
    $this = $(this)
    next =
      switch evt.keyCode
        when 37 # left
          $this.trigger('movehorizontally', -1)
          # XXX selects[(current + num_selects - 1) % num_selects]
        when 39 # right
          $this.trigger('movehorizontally', +1)
          # XXX selects[(current + 1) % num_selects]
        when 38 # up
          $this.trigger('movevertically', -1)
          # XXX $selected_li = $(evt.target).find('li.selected')
          # XXX $li = $selected_li.prev()
          # XXX selects[current]
        when 40 # down
          $this.trigger('movevertically', +1)
          # XXX $selected_li = $(evt.target).find('li.selected')
          # XXX $li = $selected_li.next()
          # XXX selects[current]
        when 32
          $this.trigger('togglecurrent')
        else
          pass_through = true
    unless pass_through
      evt.stopPropagation()
      evt.preventDefault()

  move_vertically = ($ul, dir, klass) ->
    $li = $()
    $li = $ul.find('li.selectcursor') if klass == 'selectcursor'
    $li = $ul.find('li.selected').first() unless $li.length
    $li = $ul.find('li:first-child') unless $li.length
    $next_li =
      if dir == +1
        $li.next()
      else if dir == -1
        $li.prev()
      else
        $li
    if $next_li.length
      $li.removeClass(klass)
      $next_li.addClass(klass)
      $ul.trigger('update')
      scroll_into_view($next_li)

  scroll_into_view = ($li) ->
    ul = $li.closest('ul')[0]
    li = $li[0]
    ul_top = ul.scrollTop
    ul_bottom = ul_top + ul.clientHeight - li.clientHeight
    pos = li.offsetTop - ul.offsetTop
    if pos < ul_top
      li.scrollIntoView(true)
    else if pos > ul_bottom
      li.scrollIntoView(false)

  $selects.on 'movevertically', '.uniselect', (evt, dir) ->
    move_vertically($(this), dir, 'selected')
  $selects.on 'movevertically', '.multiselect', (evt, dir) ->
    move_vertically($(this), dir, 'selectcursor')

  $selects.on 'movehorizontally', 'ul', (evt, dir) ->
    current_index = selects.indexOf($(this).prop('id'))
    next_id = selects[(current_index + num_selects + dir) % num_selects]
    $next_ul = $("##{next_id}")
    $next_ul.focus()
    #if $next_ul.hasClass('uniselect')
      #unless $next_ul.find('li.selected').length
        #$next_ul.find('li:first-child').addClass('selected')
    $next_ul.trigger('movevertically', 0)
    $next_ul.trigger('update')

  $selects.on 'togglecurrent', '.multiselect', (evt, dir) ->
    $ul = $(this)
    $li = $ul.find('li.selectcursor')
    $li.toggleClass('selected')

  get_selector = ->
    selected_tag = $tag.find('li.selected').text()
    selected_attr = $attr.find('li.selected').text()
    selected_words = $word.find('li.selected').map(-> $(this).text())
    if selected_words.length
      "#{selected_tag}[#{selected_attr}: #{selected_words.get().join(' ')}]"
    else if selected_attr.length
      "#{selected_tag}[#{selected_attr}]"
    else
      selected_tag

  window.parse_selector = (selector) ->
    matches = /^([^\]\[]+)(?:\[([^:]*)(?::\s*([^\]]*))?\])?$/.exec(selector)
    [_, tag, attr, vals] = matches
    data = [tag]
    data.push(attr) if attr
    data.push((vals.split(/\s+/))...) if vals
    data

  dragged_element_original_text = null
  insert_row_timer = null
  $inserted_row = $()
  $dragged = null
  drop_ok = false
  dragged_selector = null
  original_column = null
  drag_mode = null
  delete_inserted_row = ->
    $inserted_row.remove()
    $inserted_row = $()
  $('#tag, #attr, #word').on 'dragstart', 'li', (evt) ->
    $('#independent, #decoration, #object, #metainfo').addClass('droppable')
    drop_ok = false
    original_column = null
    $dragged = $(evt.target)
    noselect = $dragged.hasClass('selected')
    $ul = $dragged.closest('ul')
    $ul.trigger('customselect', { li: $dragged, noselect: noselect })
    $ul.trigger('update')
    dragged_element_original_text = $dragged.text()
    dragged_selector = get_selector()
    $dragged.text(dragged_selector)
  $('#independent, #decoration, #object, #metainfo').on 'dragstart', 'li', (evt) ->
    drop_ok = false
    $dragged = $(evt.target)
    original_column = $dragged.closest('ul').prop('id')
    dragged_selector = $dragged.text()
    $("#tag, #attr, #values, #independent, #decoration, #object, #metainfo").addClass('droppable')
  $selects.on 'drag', 'li', (evt) ->
    if dragged_element_original_text
      $dragged = $(evt.target)
      $dragged.text(dragged_element_original_text)
      dragged_element_original_text = null
  $selects.on 'dragover', '.droppable, .droppable li', (evt) ->
    evt.preventDefault()
  $selects.on 'dragenter', 'li:not(.inserted)', (evt) ->
    return if $(evt.target).closest('.selects').hasClass('untagged')
    clearTimeout(insert_row_timer)
    insert_row_timer = setTimeout((->
      delete_inserted_row()
      $inserted_row = $('<li class="inserted">&nbsp;</li>').insertBefore(evt.target)
    ), 500)
  $selects.on 'dragleave', '.inserted', (evt) ->
    delete_inserted_row()
    clearTimeout(insert_row_timer)
    insert_row_timer = null
  $selects.on 'drop', '.droppable li, .droppable', (evt) ->
    evt.preventDefault()
    evt.stopPropagation()
    drop_ok = true
    $target = $(evt.target)
    $ul = $target.closest('ul')
    if original_column
      $dragged.remove()
    target_column = $ul.prop('id')
    target_tagged = $ul.closest('.selects').hasClass('tagged')
    if target_tagged
      unless $target.hasClass('inserted')
        delete_inserted_row()
        $inserted_row = $('<li class="inserted"></li>').appendTo($ul)
      $inserted_row.text(dragged_selector)
    else
      target_column = null
    $inserted_row = $()
    pos =
      if $target.hasClass('inserted')
        $target.index()
      else
        -1
    $.post(dataset_url + '/step', {
      previous: original_column
      column: target_column
      pos: pos,
      selector: dragged_selector
    }, (->
      location.reload(true)
    ))
    original_column = null
  $selects.on 'dragend', (evt) ->
    $('.droppable').removeClass('droppable')
    delete_inserted_row() unless drop_ok
    clearTimeout(insert_row_timer)
