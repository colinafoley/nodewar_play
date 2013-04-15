# -----------------------------------------------------------------------------
#                     ~ The Obsidian Shards ~
#                          @colinafoley
# -----------------------------------------------------------------------------

ai.step = (o) ->
  if o.me.queen then queenStep o else droneStep o

speed_change_fear = 50
threat_thresh = 0.5

queenStep = (o) ->
  report_queen_position o

report_queen_position = (o) ->
  o.mothership.queen_position = o.me.pos
  o.mothership.queen_guard_positions = get_queen_guard_positions o

get_queen_guard_positions = (o) ->
  guard_position_origin = o.mothership.queen_position
  number_of_guard_positions = get_number_of_guard_positions o.ships
  degree_position_interval = 360/number_of_guard_positions

  guard_positions = []
  for i in [0..number_of_guard_positions]
    degree_to_position = i*degree_position_interval
    x = guard_position_origin[0] + Math.cos(degree_to_position) + 50
    y = guard_position_origin[1] + Math.sin(degree_to_position) + 50
    guard_positions[i] = [x, y]

  return guard_positions

get_number_of_guard_positions = (ships) ->
  count = 0

  for ship in ships
    if ship.friendly then count++

  return count


droneStep = (o) ->
  return maintain_position_in_relation_to_queen o

maintain_position_in_relation_to_queen = (o) ->
  torque = 0
  thrust = 0
  guard_index = o.me.ship_id
  guard_position = o.mothership.queen_guard_positions[guard_index]

  _ref = o.lib.targeting.simpleTarget(o.me, guard_position)
  torque = _ref.torque
  thrust = .33

  return {torque, thrust}
