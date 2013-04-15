// -----------------------------------------------------------------------------
//                     ~ The Obsidian Rocks ~
//                          @colinafoley
// -----------------------------------------------------------------------------
//clone from The BOOBY

ai.step = function(o) {
  if (o.me.queen) {
    return queenStep(o);
  } else {
    return droneStep(o);
  }
};

var my_start_pos = null,
  speed_change_fear = 50,
  threat_thresh = 0.5;

function queenStep (o) {
  report_queen_position(o);
  var threats = get_threats(o),
    new_target = find_ideal_position(o, threats),
    _ref = o.lib.targeting.simpleTarget(o.me, new_target),
    torque = _ref.torque,
    thrust = Math.pow(threats[0].threat_factor, 0.1) - 0.95;
  return {
    torque: torque,
    thrust: thrust,
    label: ~~threats[0].threat_factor
  };
}

function report_queen_position(o) {
  o.mothership.queen_position = o.me.pos;
  o.mothership.queen_guard_positions = get_queen_guard_positions(o);
}

function get_queen_guard_positions(o) {
  guard_position_origin = o.mothership.queen_position;
  number_of_guard_positions = o.ships.length;
  guard_positions = new Array();
  degree_position_interval = 360/number_of_guard_positions;
  for (i=0; i < number_of_guard_positions; i++) {
    degree_to_position = i*degree_position_interval;
    x = guard_position_origin[0] + Math.cos(degree_to_position) + 1;
    y = guard_position_origin[1] + Math.sin(degree_to_position) + 1;
    guard_positions[i] = new Array(x, y);
  }
  return guard_positions;
}

function get_threats (o) {
  if (my_start_pos === null) {
    my_start_pos = o.me.pos;
  }
  var _ref1 = o.lib.vec.toPolar(o.me.pos),
    radius = _ref1[0],
    angle = _ref1[1],
    edge = o.lib.vec.fromPolar([o.game.moon_field, angle]),
    exit = get_board_exit_pos(o),
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
        type:  o.ships[0].friendly ? 'friendly ship' : 'enemy ship'
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
    ].map(function (threat) {
      threat.rel_vel = o.lib.vec.diff(o.me.vel, threat.vel);
      threat.speed_toward = o.lib.physics.speedToward(threat.rel_vel, o.me.pos, threat.pos) + speed_change_fear;
      threat.time_threat = threat.speed_toward > 0 ? threat.dist / threat.speed_toward : Infinity;
      threat.dir = o.lib.targeting.dir(o.me, threat.pos);
      threat.threat_factor = threat_factor(threat);
      return threat;
    }).sort(function (a, b) {
      return b.threat_factor - a.threat_factor;
    });
  return threats;
}

function threat_factor (t) {
  var res = 1 / t.time_threat;
  res *= res;
  if (t.type === "moon") {
    res *= 6;
  } else if (t.type === "friendly ship") {
    res *= 2;
  } else if (t.type === "start position") {
    res *= 2;
  } else if (t.type === "edge") {
    res *= 5;
  }
  return res;
}

function find_ideal_position(o, threats) {
  var total_weight = 0,
    target = [0, 0];
  threats.forEach(function (t) {
    var target_diff = o.lib.vec.diff(o.me.pos, t.pos),
      n_diff = o.lib.vec.normalized(target_diff),
      diff = o.lib.vec.times(n_diff, t.threat_factor);
    total_weight += t.threat_factor;
    target[0] += diff[0];
    target[1] += diff[1];
  });
  target[0] /= total_weight;
  target[1] /= total_weight;
  return o.lib.vec.sum(o.me.pos, target);
}

function get_board_exit_pos(o) {
  var t = 0,
    dt = 0.05
    ddt = 0.025,
    maxt = 10,
    _ref = o.me.vel,
    vx = _ref[0],
    vy = _ref[1],
    _ref1 = o.me.pos,
    px = _ref1[0],
    py = _ref1[1],
    rad_sq = o.game.moon_field * o.game.moon_field;
  while ((t < maxt) && (px * px + py * py < rad_sq)) {
    t += dt;
    px += vx * dt;
    py += vy * dt;
    dt += ddt;
  }
  return [px, py];
}

function droneStep(o) {
  return maintain_position_in_relation_to_queen(o);
}

function maintain_position_in_relation_to_queen(o) {
  torque = 0;
  thrust = 0;
  guard_index = o.me.ship_id;
  guard_positions = o.mothership.queen_guard_positions
  guard_positions = ( typeof guard_positions != 'undefined' && guard_positions instanceof Array ) ? guard_positions : []
  guard_position = guard_positions[guard_index - 1]

  _ref = o.lib.targeting.simpleTarget(o.me, guard_position);
  torque = _ref.torque;
  thrust = .33;
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

