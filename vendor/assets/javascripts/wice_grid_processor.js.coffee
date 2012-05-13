class WiceGridProcessor
  constructor: (@name, @base_request_for_filter, @base_link_for_show_all_records, @link_for_export, @parameter_name_for_query_loading, @parameter_name_for_focus, @environment) ->
    @filter_declarations = new Array();
    @checkIfJsFrameworkIsLoaded()

  checkIfJsFrameworkIsLoaded :  ->
    if ! jQuery
      alert "jQuery not loaded, WiceGrid cannot proceed!"

  toString :  ->
    "<WiceGridProcessor instance for grid '" + @name + "'>"


  process : (dom_id_to_focus)->
    window.location = @build_url_with_params(dom_id_to_focus)


  set_process_timer : (dom_id_to_focus)->

    if @timer
      clearTimeout(@timer)
      @timer = null

    processor = this

    @timer = setTimeout(
      -> processor.process(dom_id_to_focus)
      1000
    )

  reload_page_for_given_grid_state : (grid_state)->
    request_path = @grid_state_to_request(grid_state)
    window.location = @append_to_url(@base_link_for_show_all_records, request_path)


  load_query : (query_id)->
    request = @append_to_url(
      @build_url_with_params()
      @parameter_name_for_query_loading +  encodeURIComponent(query_id)
    )

    window.location = request

  save_query : (field_id, query_name, base_path_to_query_controller, grid_state, input_ids)->
    if input_ids instanceof Array
      input_ids.each (dom_id) ->
        grid_state.push(['extra[' + dom_id + ']', $('#'+ dom_id)[0].value])


    request_path = @grid_state_to_request(grid_state)

    jQuery.ajax
      url: base_path_to_query_controller
      async: true
      data: request_path + '&query_name=' + encodeURIComponent(query_name)
      dataType: 'script'
      success:  -> $('#' + field_id).val('')
      type: 'POST'

  grid_state_to_request : (grid_state)->
    jQuery.map(
      grid_state
      (pair) -> encodeURIComponent(pair[0]) + '=' + encodeURIComponent(pair[1])
    ).join('&')


  append_to_url : (url, str)->

    sep = if url.indexOf('?') != -1
      if /[&\?]$/.exec(url)
        ''
      else
        '&'
    else
      '?'
    url + sep + str

  build_url_with_params : (dom_id_to_focus)->
    results = new Array()
    _this =  this
    jQuery.each(
      @filter_declarations
      (i, filter_declaration)->
        param = _this.read_values_and_form_query_string(filter_declaration.filter_name, filter_declaration.detached, filter_declaration.templates, filter_declaration.ids)

        if param && param != ''
          results.push(param)
    )

    res = @base_request_for_filter
    if  results.length != 0
      all_filter_params = results.join('&')
      res = @append_to_url(res, all_filter_params)

    if dom_id_to_focus
      res = @append_to_url(res, @parameter_name_for_focus + dom_id_to_focus)

    res



  reset : ->
    window.location = @base_request_for_filter


  export_to_csv : ->
    window.location = @link_for_export


  register : (func)->
    @filter_declarations.push(func)


  read_values_and_form_query_string : (filter_name, detached, templates, ids)->
    res = new Array()

    for i in [0 .. templates.length-1]

      if $(ids[i]) == null
        if this.environment == "development"
          message = 'WiceGrid: Error reading state of filter "' + filter_name + '". No DOM element with id "' + ids[i] + '" found.'
          if detached
            message += 'You have declared "' + filter_name + '" as a detached filter but have not output it anywhere in the template. Read documentation about detached filters.'

          alert(message);

        return ''

      el = $('#' + ids[i])

      if el[0] && el[0].type == 'checkbox'
        if el[0].checked
          val = 1;
      else
        val = el.val()

      if val instanceof Array
        for j in [0 .. val.length-1]
          if val[j] && val[j] != ""
            res.push(templates[i] + encodeURIComponent(val[j]))

      else if val &&  val != ''
        res.push(templates[i]  + encodeURIComponent(val));


    res.join('&');

  this


WiceGridProcessor._version = '3.2'

window['WiceGridProcessor'] = WiceGridProcessor