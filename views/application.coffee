jQuery ->
  $.each vans_warped_locations,  (index, location) ->
    $.ajax
      url: '/weather.json'
      dataType: 'json'
      data:
        city: location.location
      success: (data) ->
        location_id = "#location_" + (index+1)
        $(location_id).find('.temperature').html(data.current_observation.temperature_string)
