# -----------------------------------------------------------------------------
#                     ~ The Guards ~
#                          @colinafoley
# -----------------------------------------------------------------------------

my_start_pos      = null
speed_change_fear = 50
threat_thresh     = 0.5
ship_key          = ""
ship_key          += "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".charAt(Math.floor(Math.random() * "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".length)) for i in [0..5]

ai.step = (o) ->
  if o.me.queen then queenStep o else droneStep o

queenStep = (o) ->
  o.mothership.fleet = [] unless o.mothership.fleet?
  report_queen_position o

  threats = get_threats o
  new_target = find_ideal_position(o, threats)
  _ref = o.lib.targeting.simpleTarget(o.me, new_target)
  torque = _ref.torque
  thrust = Math.pow(threats[0].threat_factor, 0.1) - 0.95
  label = ~~threats[0].threat_factor

  return {torque, thrust, label}

get_threats = (o) ->
  if my_start_pos is null
    my_start_pos = o.me.pos

  _ref1 = o.lib.vec.toPolar(o.me.pos)
  radius = _ref1[0]
  angle = _ref1[1]
  edge = o.lib.vec.fromPolar([o.game.moon_field, angle])
  exit = get_board_exit_pos(o)

  threats = [
    {
      pos: edge,
      dist: o.lib.vec.dist(o.me.pos, edge),
      vel: [0, 0],
      type: 'edge'
    },
    {
      pos: o.moons[0].pos,
      vel: o.moons[0].vel,
      dist: o.moons[0].dist - o.moons[0].radius,
      type: 'moon'
    },
    {
      pos:  o.ships[0].pos,
      dist:  o.ships[0].dist,
      vel:  o.ships[0].vel,
      type:  if o.ships[0].friendly then 'friendly ship' else 'enemy ship'
    },
    {
      pos: exit,
      dist: o.lib.vec.dist(o.me.pos, exit),
      vel: [0, 0],
      type: 'exit'
    },
    {
      pos: my_start_pos,
      dist: o.lib.vec.dist(o.me.pos, my_start_pos),
      vel: [0, 0],
      type: 'start position'
    }
  ]

  threats.map (threat) ->
    threat.rel_vel = o.lib.vec.diff(o.me.vel, threat.vel)
    threat.speed_toward = o.lib.physics.speedToward(threat.rel_vel, o.me.pos, threat.pos) + speed_change_fear
    threat.time_threat = if threat.speed_toward > 0 then threat.dist / threat.speed_toward else Infinity
    threat.dir = o.lib.targeting.dir o.me, threat.pos
    threat.threat_factor = if o.me.queen then threat_factor threat else drone_threat_factor threat
    return threat

  threats.sort (a, b) ->
    return b.threat_factor - a.threat_factor

  return threats

find_ideal_position = (o, threats) ->
  total_weight = 0
  target = [0, 0]

  for threat in threats
    target_diff = o.lib.vec.diff(o.me.pos, threat.pos)
    n_diff = o.lib.vec.normalized(target_diff)
    diff = o.lib.vec.times(n_diff, threat.threat_factor)
    total_weight += threat.threat_factor
    target[0] += diff[0]
    target[1] += diff[1]

  target[0] /= total_weight
  target[1] /= total_weight

  return o.lib.vec.sum o.me.pos, target

threat_factor = (t) ->
  res = 1/ t.time_threat
  res *= res

  switch t.type
    when "moon" then res *= 6
    when "friendly ship" then res = 1 #ignore friendlies
    when "start position" then res *= 2
    when "edge" then res *= 5

  return res

drone_threat_factor = (t) ->
  res = 1/t.time_threat
  res *= res

  switch t.type
    when "moon" then res *= 18 #moons are extra scary
    when "friendly ship", "start position" then res *= 2
    when "edge" then res *= 5

  return res

get_board_exit_pos = (o) ->
  t = 0
  dt = 0.05
  ddt = 0.025
  maxt = 10
  _ref = o.me.vel
  vx = _ref[0]
  vy = _ref[1]
  _ref1 = o.me.pos
  px = _ref1[0]
  py = _ref1[1]
  rad_sq = o.game.moon_field * o.game.moon_field

  while t < maxt and px*px + py*py < rad_sq
    t += dt
    px += vx * dt
    py += vy * dt
    dt += ddt

  return [px, py]

report_queen_position = (o) ->
  o.mothership.queen_position = o.me.pos
  o.mothership.queen_guard_positions = get_queen_guard_positions o

get_queen_guard_positions = (o) ->
  guard_position_origin = o.mothership.queen_position
  number_of_guard_positions = o.mothership.fleet.length
  degree_position_interval = 360/number_of_guard_positions

  guard_positions = {}
  for i in [0..number_of_guard_positions]
    degree_to_position = i*degree_position_interval
    x = guard_position_origin[0] + Math.cos(degree_to_position) + 50
    y = guard_position_origin[1] + Math.sin(degree_to_position) + 50
    index = o.mothership.fleet[i]
    guard_positions[index] = [x, y]

  return guard_positions

droneStep = (o) ->
  report_in o
  return maintain_position_in_relation_to_queen o

report_in = (o) ->
  if o.mothership.fleet.indexOf(ship_key) is -1 then o.mothership.fleet.push ship_key

maintain_position_in_relation_to_queen = (o) ->
  torque = thrust = 0
  guard_index = ship_key
  guard_position = o.mothership.queen_guard_positions[guard_index]
  guard_position = o.me.pos unless guard_position?

  threats = get_threats o
  if threats[0].threat_factor > 24
    new_target  = find_ideal_position(o, threats)
    _ref        = o.lib.targeting.simpleTarget(o.me, new_target)
    torque      = _ref.torque
    thrust      = Math.pow(threats[0].threat_factor, 0.1) - 0.95
    label = ~~threats[0].threat_factor
    return {torque, thrust, label}


  return smart_move(o, guard_position)

position_factor = (o, guard_position) ->
  return o.lib.vec.dist o.me.pos, guard_position

smart_move = (o, p) ->
  myPos = o.me.pos
  deltaPos = o.lib.vec.diff(p, myPos)
  vel = deltaPos
  move_velocity(o, o.me, vel)

move_velocity = (o, me, vel) ->
  myVel = me.vel
  deltaVel = o.lib.vec.diff(vel, myVel)
  aimPos = o.lib.vec.sum(deltaVel, me.pos)
  o.lib.targeting.simpleTarget(me, aimPos)
