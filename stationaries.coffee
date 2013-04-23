# -----------------------------------------------------------------------------
#                      ~ The Stationaries ~
#                          @zawutuckatez
# -----------------------------------------------------------------------------

speed = 5

ai.step = (o) ->
  step(o)

step = (o) ->
  if not o.me.queen
    return stepOther(o)
  
  # Queen instructions: Move either clockwise or counterclockwise, depending on the conditions on either side.
  r = o.game.moon_field - 40
  [radius, angle] = o.lib.vec.toPolar(o.me.pos)
  newPos = o.lib.vec.fromPolar([r, o.lib.ang.rescale(angle + findDir(o))])
  theSpeed = getSpeed(o)
  vel = o.lib.vec.times(o.lib.vec.diff(newPos, o.me.pos), theSpeed)
  moveVelocity(o, o.me, vel)

getClosestMoonThreat = (o) ->
  minMoon = { dist : Infinity }
  minMoonDist = Infinity
  for i in [0..o.moons.length-1]
    moon = o.moons[i]
    speed = o.lib.physics.speedToward(o.lib.vec.sum(o.me.vel, moon.vel), o.me.pos, moon.pos)
    if speed < 0
      continue
    dist = Math.min(moon.dist / 2, moon.dist / speed)
    if dist < minMoonDist
      minMoon = moon
      minMoonDist = dist
  { minMoon, minMoonDist }

stepOther = (o) ->
  # Minion instructions: If the moon_field is close, avoid it. If a moon is close, avoid it. Otherwise, attack the enemy queen.
  if o.game.time < 3
    if o.me.pos[1] < 0
      return smartMove(o, [0, -130])
    else
      return smartMove(o, [0, 130])
  [r, a] = o.lib.vec.toPolar(o.me.pos)
  if o.game.moon_field - r < 30
    return smartMove(o, [0, 0])
  moonThreat = getClosestMoonThreat(o)
  if moonThreat.minMoonDist < 2
    return o.lib.targeting.simpleTarget(o.me, o.lib.vec.diff(o.me.pos, o.lib.vec.diff(moonThreat.minMoon.pos, o.me.pos)))
  queen = findEnemyQueen(o)
  myVel = o.lib.vec.diff(queen.pos, o.me.pos)
  myVel = o.lib.vec.times(o.lib.vec.normalized(myVel), (100 + 1000 / queen.dist) / (2 * o.me.area_frac))
  moveVelocity(o, o.me, myVel)

findEnemyQueen = (o) ->
  for i in [0..o.ships.length-1]
    if o.ships[i].queen and not o.ships[i].friendly
      return o.ships[i]

findEnemy = (o) ->
  for i in [0..o.ships.length-1]
    if not o.ships[i].friendly
      return o.ships[i]

findClosestBadThing = (o) ->
  if findEnemy(o).dist < o.moons[0].dist
    findEnemy(o)
  else
    o.moons[0]

getSpeed = (o) ->
  afrac = o.me.area_frac
  panicMeter = speed
  panicMeter *= ( 1 / (findClosestBadThing(o).dist / 20) ) * 3
  panicMeter *= (1/afrac)
  return Math.min(panicMeter, 8)

findDir = (o) ->
  # Look in the mothership to see if I've logged what direction I'm currently going in.
  # I'll only use this "default value" if I'm undecided as to which direction to go.
  id = o.me.ship_id
  currentDir = 0.1
  if o.mothership[id]
    currentDir = o.mothership[id]
  count1 = 0
  count2 = 0
  myAng = o.lib.vec.ang(o.me.pos)
  for i in [0..o.ships.length-1]
    ship = o.ships[i]
    if ship.dist > 50  # we only want close enemy ships
      continue
    shipAng = o.lib.vec.ang(ship.pos)
    diff = o.lib.ang.diff(myAng, shipAng)
    if diff < 0
      count1 += 1
    else
      count2 += 1
  for i in [0..o.moons.length-1]
    moon = o.moons[i]
    if moon.dist > 50
      continue
    moonAng = o.lib.vec.ang(moon.pos)
    diff = o.lib.ang.diff(myAng, moonAng)
    if diff < 0
      count1 += 5
    else
      count2 += 5
  
  if count1 < count2
    o.mothership[id] = 0.1
    return 0.1
  if count1 > count2
    o.mothership[id] = -0.1
    return -0.1
  else
    return currentDir

moveVelocity = (o, me, vel) ->
  myVel = me.vel
  deltaVel = o.lib.vec.diff(vel, myVel)
  aimPos = o.lib.vec.sum(deltaVel, me.pos)
  o.lib.targeting.simpleTarget(me, aimPos)

smartMove = (o, p) -> 
  myPos = o.me.pos
  deltaPos = o.lib.vec.diff(p, myPos)
  vel = deltaPos
  moveVelocity(o, o.me, vel)

log = (obj, l) ->
  obj.label = l
  obj
