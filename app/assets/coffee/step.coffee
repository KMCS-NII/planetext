$ ->
  $tag = $('#tag')
  $attr = $('#attr')
  $word = $('#word')
  $value = $('#value')
  $instance = $('#instance')

  select_li = (evt) ->
    $(evt.target).closest('ul').find('li.selected').removeClass('selected')
    $selected_li = $(evt.target).addClass('selected')
  fill_instances_by_word = ->
    matching = null
    selected_tag = $tag.find('li.selected').text()
    selected_attr = $attr.find('li.selected').text()
    attr = unknowns[selected_tag][selected_attr]
    $word.find('li.selected').map ->
      word = this.textContent
      word_instances = attr[0][word]
      if matching
        for index of matching
          delete matching[index] unless index in word_instances
      else
        matching = {}
        matching[index] = true for index in word_instances
    unique_values = {}
    for index in Object.keys(matching)
      data = attr[1][index]
      str = "#{data[2]} (#{data[0]}-#{data[1]})"
      $('<li>').text(str).appendTo($instance)
      unique_values[attr[1][index][3]] = true;
    unique_values

  $tag.on 'update', (evt, selected_tag) ->
    $attr.empty()
    $word.empty()
    $value.empty()
    $instance.empty()
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
  $tag.on 'click', ->
    $tag.find('li.selected').removeClass('selected')
    $tag.trigger('update')
  # TODO convert the other click events into click + update (+ select?)
  # to allow dragstart to call selectively (XXX think it through)
  $tag.on 'click', 'li', (evt) ->
    evt.stopPropagation()
    $selected_li = select_li(evt)
    selected_tag = $selected_li.text()
    $tag.trigger('update', selected_tag)
  $attr.on 'click', ->
    $attr.find('li.selected').removeClass('selected')
    $word.empty()
    $value.empty()
    $instance.empty()
  $attr.on 'click', 'li', (evt) ->
    evt.stopPropagation()
    $word.empty()
    $value.empty()
    $instance.empty()
    $selected_li = select_li(evt)
    selected_tag = $tag.find('li.selected').text()
    selected_attr = $selected_li.text()
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
  $word.on 'click', ->
    $word.find('li.selected').removeClass('selected')
    $value.empty()
    $instance.empty()
  $word.on 'click', 'li', (evt) ->
    evt.stopPropagation()
    $value.empty()
    $instance.empty()
    $selected_li = select_li(evt)
    unique_values = fill_instances_by_word()
    for value in Object.keys(unique_values)
      $('<li>').text(value).appendTo($value)
  $value.on 'click', ->
    $value.find('li.selected').removeClass('selected')
    $instance.empty()
    fill_instances_by_word()
  $value.on 'click', 'li', (evt) ->
    evt.stopPropagation()
    $instance.empty()
    $selected_li = select_li(evt)
    selected_tag = $tag.find('li.selected').text()
    selected_attr = $attr.find('li.selected').text()
    selected_value = $selected_li.text()
    attr = unknowns[selected_tag][selected_attr]
    known = {}
    for data in attr[1]
      if data[3] == selected_value
        str = "#{data[2]} (#{data[0]}-#{data[1]})"
        unless known[str]
          $('<li>').text(str).appendTo($instance)
          known[str] = true
  $instance.on 'click', ->
    $instance.find('li.selected').removeClass('selected')
    # TODO clear the instance
  $instance.on 'click', 'li', (evt) ->
    evt.stopPropagation()
    $selected_li = select_li(evt)
    # TODO show the instance

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
  $('.selects ul').keydown (evt) ->
    current = selects.indexOf(evt.target.id)
    next =
      switch evt.keyCode
        when 37 # left
          selects[(current + num_selects - 1) % num_selects]
        when 39 # right
          selects[(current + 1) % num_selects]
        when 38 # up
          $selected_li = $(evt.target).find('li.selected')
          $li = $selected_li.prev()
          selects[current]
        when 40 # down
          $selected_li = $(evt.target).find('li.selected')
          $li = $selected_li.next()
          selects[current]
    if next
      evt.stopPropagation()
      evt.preventDefault()
      if $selected_li # up, down
        if (li = $li[0])
          $selected_li.removeClass('selected')
          $li.addClass('selected')
          ul = evt.target
          ul_top = ul.scrollTop
          ul_bottom = ul_top + ul.clientHeight - li.clientHeight
          pos = li.offsetTop - ul.offsetTop
          if pos < ul_top
            li.scrollIntoView(true)
          else if pos > ul_bottom
            li.scrollIntoView(false)
      else # left, right
        $ul = $("##{next}")
        $ul.focus()
        $li = $ul.find('li.selected')
        $li = $ul.find('li:first-child') unless $li.length
      if $li.length
        $li[0].click()

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
    evt.target.click()
    $dragged = $(evt.target)
    dragged_element_original_text = $dragged.text()
    dragged_selector = get_selector()
    $dragged.text(dragged_selector)
  $('#independent, #decoration, #object, #metainfo').on 'dragstart', 'li', (evt) ->
    drop_ok = false
    $dragged = $(evt.target)
    original_column = $dragged.closest('ul').prop('id')
    dragged_selector = $dragged.text()
    $("#tag, #attr, #values, #independent, #decoration, #object, #metainfo").addClass('droppable')
  $('.selects').on 'drag', 'li', (evt) ->
    if dragged_element_original_text
      $dragged = $(evt.target)
      $dragged.text(dragged_element_original_text)
      dragged_element_original_text = null
  $('.selects').on 'dragover', '.droppable, .droppable li', (evt) ->
    evt.preventDefault()
  $('.selects').on 'dragenter', 'li:not(.inserted)', (evt) ->
    return if $(evt.target).closest('.selects').hasClass('untagged')
    clearTimeout(insert_row_timer)
    insert_row_timer = setTimeout((->
      delete_inserted_row()
      $inserted_row = $('<li class="inserted">&nbsp;</li>').insertBefore(evt.target)
    ), 500)
  $('.selects').on 'dragleave', '.inserted', (evt) ->
    delete_inserted_row()
    clearTimeout(insert_row_timer)
    insert_row_timer = null
  $('.selects').on 'drop', '.droppable li, .droppable', (evt) ->
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
  $('.selects').on 'dragend', (evt) ->
    $('.droppable').removeClass('droppable')
    delete_inserted_row() unless drop_ok
    clearTimeout(insert_row_timer)
