// -----------------------------------------------------------------------------
//                     ~ The Obsidian Rocks ~
//                          @colinafoley
// -----------------------------------------------------------------------------

ai.step = function(o) {
  if (o.me.queen) {
    return queenStep(o);
  } else {
    return droneStep(o);
  }
};

function queenStep(o) {
  return {
    torque: 0,
    thrust: 0,
  }
}
function droneStep(o) {
  var md, spd, thrust, torque;
  torque = 0;
  thrust = 0;
  spd = speed_to_nearest_moon(o);
  md = dist_to_nearest_moon(o);
  if ((spd > 0.1) && (md < 0.8 * o.game.moon_field)) {
    thrust = 1.0;
  }
  if (o.me.queen) {
      thrust = 0;
  }
  return {
    torque: torque,
    thrust: thrust
  };
}

speed_to_nearest_moon = function(o) {
  return o.lib.physics.speedToward(o.me.vel, o.me.pos, o.moons[0].pos);
};

dist_to_nearest_moon = function(o) {
  return o.moons[0].dist;
};
