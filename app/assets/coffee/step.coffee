$ ->
  disable_empty = ->
    disable_if_empty($tag)
    disable_if_empty($attr)
    disable_if_empty($word)
    disable_if_empty($value)
    disable_if_empty($instance)
  disable_if_empty = ($select) ->
    empty = $select.find('li').length == 0
    $select.toggleClass('disabled', empty)
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

  $tag = $('#tag')
  $attr = $('#attr')
  $word = $('#word')
  $value = $('#value')
  $instance = $('#instance')

  $tag.click ->
    $tag.find('li.selected').removeClass('selected')
    $attr.empty()
    $word.empty()
    $value.empty()
    $instance.empty()
    disable_empty()
  $tag.on 'click', 'li', (evt) ->
    evt.stopPropagation()
    $attr.empty()
    $word.empty()
    $value.empty()
    $instance.empty()
    return unless evt.target.nodeName == "LI"
    $selected_li = select_li(evt)
    selected_tag = $selected_li.text()
    known = {}
    for attr_name, attr of unknowns[selected_tag]
      unless attr_name == ''
        $('<li draggable="true">').text(attr_name).appendTo($attr)
      for data in attr[1]
        str = "#{data[2]} (#{data[0]}-#{data[1]})"
        unless known[str]
          $('<li>').text(str).appendTo($instance)
          known[str] = true
    disable_empty()
  $attr.click ->
    $attr.find('li.selected').removeClass('selected')
    $word.empty()
    $value.empty()
    $instance.empty()
    disable_empty()
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
    disable_empty()
  $word.click ->
    $word.find('li.selected').removeClass('selected')
    $value.empty()
    $instance.empty()
    disable_empty()
  $word.on 'click', 'li', (evt) ->
    evt.stopPropagation()
    $value.empty()
    $instance.empty()
    $selected_li = select_li(evt)
    unique_values = fill_instances_by_word()
    for value in Object.keys(unique_values)
      $('<li>').text(value).appendTo($value)
    disable_empty()
  $value.click ->
    $value.find('li.selected').removeClass('selected')
    $instance.empty()
    fill_instances_by_word()
    disable_empty()
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
    disable_empty()
  $instance.click ->
    $instance.find('li.selected').removeClass('selected')
    # TODO clear the instance
  $instance.on 'click', 'li', (evt) ->
    evt.stopPropagation()
    $selected_li = select_li(evt)
    # TODO show the instance

  $('.untagged ul').keydown (evt) ->
    selects = ['tag', 'attr', 'word', 'value', 'instance']
    current = selects.indexOf(evt.target.id)
    next =
      switch evt.keyCode
        when 37 # left
          selects[current - 1]
        when 39 # right
          selects[current + 1]
        when 38 # up
          $selected_li = $(evt.target).find('li.selected')
          $li = $selected_li.prev()
          if ($li.length)
            $selected_li.removeClass('selected')
            $li.addClass('selected')
          selects[current]
        when 40 # down
          $selected_li = $(evt.target).find('li.selected')
          $li = $selected_li.next()
          if ($li.length)
            $selected_li.removeClass('selected')
            $li.addClass('selected')
          selects[current]
    if next
      evt.stopPropagation()
      evt.preventDefault()
      if $selected_li # up, down
        if (li = $li[0])
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
        return if $ul.hasClass('disabled')
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
      console.log(selected_words)
      "#{selected_tag}[#{selected_attr}: #{selected_words.get().join(' ')}]"
    else if selected_attr
      "#{selected_tag}[#{selected_attr}]"
    else
      selected_tag

  dragged_element_original_text = null
  $('.untagged').on 'dragstart', 'li', (evt) ->
    evt.target.click()
    $dragged = $(evt.target)
    dragged_element_original_text = $dragged.text()
    selector = get_selector()
    $dragged.text(selector)
  $('.untagged').on 'drag', 'li', (evt) ->
    if dragged_element_original_text
      $dragged = $(evt.target)
      $dragged.text(dragged_element_original_text)
      dragged_element_original_text = null

  disable_empty()

