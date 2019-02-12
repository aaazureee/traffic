model blocked_road

global {
  graph my_graph;
  list<point> nodes;
  list<float> time_list; // list of time to arrive to next node;
  geometry shape <- square(150 #m);
  bool change_graph_action <- false;
  float seed <- 1.0; // rng seed for reproducing the same result (dev mode)

  // Category: people related variables
  int nb_people_init <- 50;
  int min_nb_people_spawn <- 10 min: 0 max: 99;
  int max_nb_people_spawn <- 20 min: 0 max: 99;
  int spawn_interval <- 20 min: 0 max: 99;

  // Category: road density count
  int low_count -> {length(road where (each.status = "low"))};
  int moderate_count -> {length(road where (each.status = "moderate"))};
  int high_count -> {length(road where (each.status = "high"))};
  int extreme_count -> {length(road where (each.status = "extreme"))};
  int traffic_jam_count -> {length(road where (each.status = "traffic_jam"))};

  // Category: road related variables
  float min_free_speed <- 7.0 #m / #s;
  float max_free_speed <- 15.0 #m / #s;
  int min_capacity_val <- 5;
  int max_capacity_val <- 10;

  // stats
  list<float> speed_list -> {people collect each.speed};
  map<string, list> speed_histmap -> {distribution_of(speed_list, 10, min_free_speed, max_free_speed)};
  int nb_people_current -> {length(people)};
  int nb_trips_completed <- 0;
  float avg_speed -> {(mean(speed_list))};
  list<my_node> top_traffic_nodes -> {reverse(my_node sort_by each.traffic_count)};
  int node_traffic_sum -> {sum(top_traffic_nodes collect each.traffic_count)};
  float node_traffic_avg -> {mean(top_traffic_nodes collect each.traffic_count)};

  init {
//    add point(10, 10) to: nodes;
//    add point(10, 90) to: nodes;
//    add point(50, 90) to: nodes;
//    add point(180, 10) to: nodes;
    add point(10, 10) to: nodes;
    add point(10, 90) to: nodes;
    add point(40, 20) to: nodes;
    add point(80, 50) to: nodes;
    add point(90, 20) to: nodes;
    add point(50, 90) to: nodes;
    add point(30, 20) to: nodes;
    add point(110, 50) to: nodes;
    add point(120, 20) to: nodes;
    add point(50, 120) to: nodes;
    add point(100, 110) to: nodes;
    loop i from: 0 to: length(nodes) - 1 {
      create my_node {
        location <- nodes[i];
      }

    }

    create road {
      shape <- line([my_node[0], my_node[1]]);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    create road {
      shape <- line([my_node[1], my_node[2]]);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    create road {
      shape <- line([my_node[2], my_node[3]]);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    create road {
      shape <- line([my_node[3], my_node[4]]);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }
    
    create road {
      shape <- line([my_node[4], my_node[5]]);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }
    
    create road {
      shape <- line([my_node[5], my_node[6]]);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }
    
    create road {
      shape <- line([my_node[6], my_node[7]]);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }
    
    create road {
      shape <- line([my_node[7], my_node[8]]);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }
    
    create road {
      shape <- line([my_node[8], my_node[9]]);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }
    
    create road {
      shape <- line([my_node[9], my_node[10]]);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }
    
    create road {
      shape <- line([my_node[9], my_node[5]]);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }
    
    create road {
      shape <- line([my_node[3], my_node[7]]);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }
    
    create road {
      shape <- line([my_node[10], my_node[7]]);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }


    //     try reverse
    ask road {
      create road {
        shape <- line(reverse(myself.shape.points));
        link_length <- myself.link_length;
        free_speed <- myself.free_speed;
        max_capacity <- myself.max_capacity;
      }

    }

    // generate graph
    my_graph <- as_edge_graph(road) with_weights (road as_map (each::each.link_length));
    // directed graph
    my_graph <- directed(my_graph);
    do create_people(nb_people_init);
    //    do create_people_test(5, 0, 2);

    //    do create_people_test(5, 1, 0);
    //    do create_people_test(30, 2, 0);

  }

  reflex generate_ppl when: every(spawn_interval) {
    do create_people(min_nb_people_spawn + rnd(max_nb_people_spawn - min_nb_people_spawn));
  }

  // empty list first then update min time
  reflex refresh_min_time {
    time_list <- [];
    do update_min_time;
    if (change_graph_action = true) {
      change_graph_action <- false;
    }

  }

  action create_people (int num_people) {
    create people number: num_people {
      int random_origin_index <- rnd(length(nodes) - 1);
      location <- nodes[random_origin_index]; // CHANGE HERE
      int random_dest_index <- rnd(length(nodes) - 1);
      loop while: random_origin_index = random_dest_index {
        random_dest_index <- rnd(length(nodes) - 1);
      }

      dest <- nodes[random_dest_index];
      try {
        shortest_path <- path_between(my_graph, location, dest);
      }

      catch {
        write "caught!!!";
        cant_find_path <- true;
        speed <- 0 #m / #s;
      }

      if (cant_find_path = false) {
        if (shortest_path = nil or length(shortest_path.edges) = 0) {
          cant_find_path <- true;
        } else {
        // Fixed road path
          fixed_edges <- shortest_path.edges collect (road(each));
          num_nodes_to_complete <- length(fixed_edges);
          current_road <- fixed_edges[current_road_index];
        }

      }

      speed <- 0 #m / #s;
      // increment traffic count at source location node
      my_node(location).traffic_count <- my_node(location).traffic_count + 1;
    }

  }

  action create_people_test (int num_people, int u_location, int u_dest) {
    create people number: num_people {
      int random_origin_index <- rnd(length(nodes) - 1);
      location <- nodes[u_location]; // CHANGE HERE
      int random_dest_index <- rnd(length(nodes) - 1);
      loop while: random_origin_index = random_dest_index {
        random_dest_index <- rnd(length(nodes) - 1);
      }

      dest <- nodes[u_dest];
      try {
        shortest_path <- path_between(my_graph, location, dest);
      }

      catch {
        write "caught!!!";
        cant_find_path <- true;
        speed <- 0 #m / #s;
      }

      if (cant_find_path = false) {
        if (shortest_path = nil or length(shortest_path.edges) = 0) {
          write "ded";
          do die;
        }
        // Fixed road path
        fixed_edges <- shortest_path.edges collect (road(each));
        num_nodes_to_complete <- length(fixed_edges);
        current_road <- fixed_edges[current_road_index];
      }

      speed <- 0 #m / #s;
    }

  }

  action update_min_time {
    list<people> selected_people <- people where ((!each.cant_find_path) and ((!each.is_in_blocked_road) or (each.is_in_blocked_road and
    each.current_road_index = each.num_nodes_to_complete - 1)));
    int dead_node_count <- -1;

    //    write "selected people here" + selected_people;
    // only ask people that is not in blocked road or people in blocked road but the dest in on that road
    ask selected_people {
    //      write string(self);
    // test fix stupid grpah problem
    //      loop edge over: my_graph.edges {
    //        write road(edge).shape.points contains self.;
    //      }
      if (is_on_node = true) {
        my_node cur_node <- (my_node inside self.location)[0];

        //        write my_node inside self.location;
        loop edge over: my_graph.edges {
          if road(edge).shape.points contains cur_node.location {
            dead_node_count <- 0;
            ask cur_node {
              self.dead_node <- false;
            }

          }

        }

        if (dead_node_count = -1) {
          dead_node_count <- 1;
          ask cur_node {
            self.dead_node <- true;
          }
          // people cant find path
          write "cant find path (no edges connecting source)";
          cant_find_path <- true;
          speed <- 0 #m / #s;
          break;
        }

      }

      // write fixed_edges;
      // shape.points[1] = target/source of polyline edge, i.e. next node
      next_node <- point(fixed_edges[current_road_index].shape.points[1]);
      //      write next_node;
      current_road <- fixed_edges[current_road_index]; // current road segment
      float true_link_length <- current_road.link_length; // link length (real_)
      //      write "True link length: " + true_link_length;
      float distance_to_next_node <- self distance_to next_node; // gama distance (2d graph)
      //      write "next node: " + next_node;
      //      write "GAMA distance: " + distance_to_next_node;
      if (is_road_jammed = true) {
        is_road_jammed <- current_road.current_volume = current_road.max_capacity; // is person stuck?
        speed <- 0 #m / #s;
      }
      //      write string(current_road.current_volume) + "/" + current_road.max_capacity;
      //      write "JAMMED STATUS: " + is_road_jammed;
      if (is_road_jammed = false) { // only do stuff is road is not jammed
      // FIND initial RATIO + speed at start of each road
        if (is_on_node = true or change_graph_action = true) {
        // Handle special road blockage, re-calculate things
          if (change_graph_action = true) {
            ratio <- true_link_length / current_road.shape.perimeter;
          } else {
            ratio <- true_link_length / distance_to_next_node;
          }

          speed <- myself.get_equi_speed(current_road.free_speed, current_road.current_volume, current_road.max_capacity);
          is_on_node <- false;
          if (is_in_blocked_road = false) {
            if (road_before_change != current_road) {
              current_road.current_volume <- current_road.current_volume + 1; // increase traffic volume of the road
            }

          }

        }

        //        write "RATIO: " + ratio;
        real_dist_to_next_node <- distance_to_next_node * ratio;
        //        write string(self) + ", speed: " + speed;
        float travel_time <- real_dist_to_next_node / speed;

        //        write "REAL travel_time: " + travel_time;
        add travel_time to: time_list;
      }

    }

    float min_time;
    if (dead_node_count != 1) {
      min_time <- min(time_list);
      ask selected_people {
        step <- min_time;
      }

    }

    //    write "Min:" + min_time;
    //    write "-----------";
  }

  // BPR equation
  float get_equi_speed (float free_speed, int current_volume, int max_capacity) {
    return free_speed / (1 + 0.15 * (current_volume / max_capacity) ^ 4);
  }

  action mouse_down_evt {
    geometry circ <- circle(1, #user_location);
    list<people> test <- people inside circ;
    if (length(test) > 0) {
      people selected_person <- test[0];
      write selected_person;
      ask selected_person {
        if (clicked = true) {
          clicked <- false;
        } else {
          clicked <- true;
        }

      }

    }

  }

  int node_counter <- 0;
}

species people skills: [moving] {
  rgb color <- rgb([rnd(255), rnd(255), rnd(255)]);
  point dest; // destination node
  path shortest_path; // shortest path
  list<road> fixed_edges;
  int num_nodes_to_complete;
  int current_road_index <- 0;
  point next_node;
  bool is_on_node <- true;
  bool clicked <- false; // gui variable
  float ratio <- 1.0;
  float real_dist_to_next_node;
  road current_road;
  bool is_road_jammed <- true;
  bool is_in_blocked_road <- false;
  bool cant_find_path <- false;
  road road_before_change <- nil;

  // Smart move
  reflex smart_move when: cant_find_path = false and is_road_jammed = false and (!is_in_blocked_road or (is_in_blocked_road and current_road_index = num_nodes_to_complete - 1)) {
  //    write "pre-speed: " + speed;
  //    write "move";
    float epsilon <- 10 ^ -5;
    //    write "DIST:" + real_dist_to_next_node;
    // change step so that person stops at node before going into new road
    //    write "Step time: " + step + "s";
    // MOVE
    do follow path: shortest_path;
    //    write "TRAVELLED: " + (self distance_to fixed_vertices[next_node_index - 1]) * ratio;
    if (real_dist_to_next_node < epsilon) {
      self.location <- next_node.location;
    }

    point prev_node <- point(fixed_edges[current_road_index].shape.points[0]);

    // CHECK IF PERSON IS ON ONE NODE
    //    if (self overlaps next_node) {
    if (self overlaps next_node) {
    //      write "OVERLAPS";
      current_road.current_volume <- current_road.current_volume - 1;
      my_node(next_node).traffic_count <- my_node(next_node).traffic_count + 1;
      // if its the final node
      if (current_road_index = num_nodes_to_complete - 1) {
      //        write "ARRIVED!";
        nb_trips_completed <- nb_trips_completed + 1;
        do die;
      } else {
        is_on_node <- true;
        is_road_jammed <- true;
        current_road_index <- current_road_index + 1;
      }

    }

  }

  aspect base {
    if (is_in_blocked_road and current_road_index = num_nodes_to_complete - 1) {
      if (clicked = true) {
        draw circle(2) at: point(self.location) color: #yellow;
        draw circle(2) at: point(self.dest) color: #cyan;
        draw polyline([self.location, self.dest]) color: #pink width: 5;
      }

    } else if (clicked = true and cant_find_path = false) {
      path new_path <- path_between(my_graph, location, dest);
      draw circle(2) at: point(new_path.source) color: #yellow;
      draw circle(2) at: point(new_path.target) color: #cyan;
      draw new_path.shape color: #pink width: 5;
    }

    if (is_in_blocked_road = true) {
      draw triangle(2.5) color: color;
    } else {
      draw circle(1.5) color: color;
    }

  }

}

species my_node {
  int node_number;
  bool dead_node <- false;
  int traffic_count <- 0;

  init {
    node_number <- node_counter;
    node_counter <- node_counter + 1;
  }

  reflex {
    write traffic_count;
  }

  aspect base {
  //    draw circle(1) color: #lightblue;
    draw string(node_number) color: #black font: font('Helvetica', 18, #plain);
  }

}

species road {
  float link_length;
  float free_speed;
  int max_capacity;
  int current_volume <- 0 min: 0 max: max_capacity;
  float link_full_percentage <- 0.0;
  rgb color;
  bool blocked <- false;
  string status;

  // user command section
  user_command "Block" action: block;
  user_command "Unblock" action: unblock;

  reflex update_traffic_status {
    link_full_percentage <- current_volume / max_capacity;
    // if double lane occurs, take them into account (x2)
    ask road {
      if myself.shape = line(reverse(self.shape.points)) {
        int accu_current_volume <- myself.current_volume + self.current_volume;
        int accu_max_capacity <- myself.max_capacity + self.max_capacity;
        link_full_percentage <- accu_current_volume / accu_max_capacity;
      }

    }

  }

  action block {
    write "block .";
    self.blocked <- true;
    // BLOCKED BOTH HERE
    ask road where (each.shape.points[1] = self.shape.points[0] and each.shape.points[0] = self.shape.points[1]) {
      blocked <- true;
    }
    // regenerate new graph without the edge/road just selected
    my_graph <- as_edge_graph(road where (!each.blocked)) with_weights (road as_map (each::each.link_length));
    // directed graph
    my_graph <- directed(my_graph);
    // global switch toggle
    change_graph_action <- true;

    // ask people that are already in the middle of the blocked road    
    //    ask (people inside self) where (each.is_on_node = false) {
    //      write "applied";
    //      is_in_blocked_road <- true;
    //    }
    ask people {
    // people that are stuck x
      if ((self.current_road.shape = myself.shape or self.current_road.shape = line(reverse(myself.shape.points))) and (is_on_node = false)) {
      //      if ((self overlaps myself) and (is_on_node = false)) {
      //        write "Stuck: " + self;
        is_in_blocked_road <- true;
      } else {
        try {
          shortest_path <- path_between(my_graph, location, dest);
        }

        catch {
          write "caught!!!! in block action";
          write string(self) + " -> cant_find_path is now true";
          cant_find_path <- true;
          speed <- 0 #m / #s;
        }

        if (cant_find_path = false) {
        //          write string(self) + " " + shortest_path;
          if (shortest_path = nil or length(shortest_path.edges) = 0) {
            write "cant find path";
            cant_find_path <- true;
            speed <- 0 #m / #s;
          } else {
            fixed_edges <- shortest_path.edges collect (road(each));
            num_nodes_to_complete <- length(fixed_edges);
            current_road_index <- 0;
            road_before_change <- current_road;
            road new_current_road <- fixed_edges[current_road_index]; // new current road after re route
            // turn around
            if (road_before_change.shape = line(reverse(new_current_road.shape.points))) {
            //              write "KUCHI block";
              road_before_change.current_volume <- road_before_change.current_volume - 1;
            }

          }

        }

      }

    }

    // ask people in blocked road but has destination outside of blocked road
    ask people where (each.is_in_blocked_road and (each.current_road_index != (each.num_nodes_to_complete - 1))) {
      write "----";
      write self;
      write self.current_road_index;
      write self.num_nodes_to_complete;
      write "----";
      speed <- 0 #m / #s;
    }

  }

  // un-block command
  action unblock {
    self.blocked <- false;
    // BLOCKED BOTH HERE
    ask road where (each.shape.points[1] = self.shape.points[0] and each.shape.points[0] = self.shape.points[1]) {
      blocked <- false;
    }
    // regenerate new graph without the edge/road just selected
    my_graph <- as_edge_graph(road where (!each.blocked)) with_weights (road as_map (each::each.link_length));
    // directed graph
    my_graph <- directed(my_graph);
    // global switch toggle
    change_graph_action <- true;

    // ask people that are already in the middle of the blocked road    
    //    ask (people inside self) where (each.is_on_node = false) {
    //      write "applied";
    //      is_in_blocked_road <- true;
    //    }
    ask people {
    // people that are stuck
      if ((self.current_road.shape = myself.shape or self.current_road.shape = line(reverse(myself.shape.points))) and (is_on_node = false)) {
      //      if ((self overlaps myself) and (is_on_node = false)) {
      //        write "Stuck: " + self;
        is_in_blocked_road <- false;
      } else {
        try {
          shortest_path <- path_between(my_graph, location, dest);
        }

        catch {
          write "caught!!!! in block action";
          write string(self) + " -> cant_find_path is now true";
          cant_find_path <- true;
          speed <- 0 #m / #s;
          break;
        }

        //          write string(self) + " " + shortest_path;
        if (shortest_path = nil or length(shortest_path.edges) = 0) {
          write "cant find path";
          cant_find_path <- true;
          speed <- 0 #m / #s;
        } else {
          fixed_edges <- shortest_path.edges collect (road(each));
          num_nodes_to_complete <- length(fixed_edges);
          current_road_index <- 0;
          cant_find_path <- false;
          road_before_change <- current_road;
          road new_current_road <- fixed_edges[current_road_index]; // new current road after reroute
          // turn around
          if (road_before_change.shape = line(reverse(new_current_road.shape.points))) {
          //            write "KUCHI unblock";
            road_before_change.current_volume <- road_before_change.current_volume - 1;
          }

        }

      }

    }

  }

  // starting condition
  // +) shortest_path, fixed_edges, num_nodes_to_complete:
  // -------------------------------
  //      shortest_path <- path_between(my_graph, location, dest);
  //      // Fixed road path
  //      fixed_edges <- shortest_path.edges collect (road(each));
  //      num_nodes_to_complete <- length(fixed_edges);
  //      reset current_road_index to 0
  // 


  //people variables 
  //  int current_road_index <- 0;
  //  point next_node;
  //  bool is_on_node <- true;// CONSIDER
  //  bool is_road_jammed <- true; // CONSIDER


  //  action remove {
  //    blocked <- true;
  //    the_graph <-  (as_edge_graph(road where (!each.blocked))) ;
  //    map<road,float> weights_map <- road as_map (each:: each.coeff_traffic);
  //    the_graph <- the_graph  with_weights weights_map;
  //    color <- #magenta;
  //  }
  //    
  //  reflex {
  //    write string(self) + ", num: " + length(people inside self);
  //  }
  aspect base {
    if (link_full_percentage <= 0.25) {
      color <- #lime;
      status <- "low";
    } else if (link_full_percentage <= 0.5) {
      color <- #blue;
      status <- "moderate";
    } else if (link_full_percentage <= 0.75) {
      color <- #yellow;
      status <- "high";
    } else {
      color <- #orange;
      status <- "extreme";
    }

    if (link_full_percentage = 1) {
      color <- #red;
      status <- "traffic_jam";
    }

    if (blocked = true) {
      color <- #purple;
    }

    draw shape color: color width: 2;
    draw string(self.shape.perimeter with_precision 2) color: #black font: font('Helvetica', 10, #plain);
  } }

experiment my_experiment type: gui {
  parameter "Min number people spawn per interval:" var: min_nb_people_spawn category: "People";
  parameter "Max number people spawn per interval:" var: max_nb_people_spawn category: "People";
  parameter "Spawn interval (in cycle):" var: spawn_interval category: "People";
  output {
    display main_display type: opengl background: #white {
      species road aspect: base;
      species people aspect: base;
      species my_node aspect: base;
      event [mouse_down] action: mouse_down_evt;
    }

    display traffic_density_chart {
      chart "Traffic density count series" type: series size: {1, 0.5} position: {0, 0} x_label: "Cycle" y_label: "Count" {
        data "Low" value: low_count color: #lime style: line;
        data "Moderate" value: moderate_count color: #blue style: line;
        data "High" value: high_count color: #yellow style: line;
        data "Extreme" value: extreme_count color: #orange style: line;
        data "Traffic jam" value: traffic_jam_count color: #red style: line;
      }

      chart "Traffic density pie chart" type: pie style: exploded size: {0.5, 0.5} position: {0, 0.5} {
        data "Low" value: low_count color: #lime;
        data "Moderate" value: moderate_count color: #blue;
        data "High" value: high_count color: #yellow;
        data "Extreme" value: extreme_count color: #orange;
        data "Traffic jam" value: traffic_jam_count color: #red;
      }

      chart "Traffic density bar chart" type: histogram size: {0.5, 0.5} position: {0.5, 0.5} x_label: "Traffic density category" y_label: "Count" {
        data "Low" value: low_count color: #lime;
        data "Moderate" value: moderate_count color: #blue;
        data "High" value: high_count color: #yellow;
        data "Extreme" value: extreme_count color: #orange;
        data "Traffic jam" value: traffic_jam_count color: #red;
      }

    }

    display speed_chart {
      chart "Average speed series" type: series size: {1, 0.5} position: {0, 0} x_label: "Cycle" y_label: "Average speed (m/s)" {
        data "Average speed" value: avg_speed color: #deepskyblue;
      }

      chart "Speed distribution" type: histogram size: {1, 0.5} position: {0, 0.5} x_label: "Speed bin (m/s)" y_label: "Frequency" {
        datalist list(speed_histmap at "legend") value: list(speed_histmap at "values");
      }

    }

    display traffic_count_at_nodes_chart {
      chart "Average traffic at 1 node" type: series size: {1, 0.5} position: {0, 0} x_label: "Cycle" y_label: "Count" {
        data "sum" value: node_traffic_avg color: #salmon;
      }

      chart "Top-k populated nodes (highest traffic)" type: histogram size: {1, 0.5} position: {0, 0.5} x_label: "Node id" y_label: "Count" {
        datalist legend: (top_traffic_nodes collect ("Node " + string(each.node_number))) value: (top_traffic_nodes collect each.traffic_count);
      }

    }

    monitor "Low density road count" value: low_count color: #lime;
    monitor "Moderate density road count" value: moderate_count color: #blue;
    monitor "High density road count" value: high_count color: #yellow;
    monitor "Extreme density road count" value: extreme_count color: #orange;
    monitor "Traffic jam count" value: traffic_jam_count color: #red;
    monitor "Current number of people" value: nb_people_current;
    monitor "Number of trips completed" value: nb_trips_completed;
    monitor "Average speed" value: avg_speed color: #deepskyblue;
    monitor "Node traffic sum" value: node_traffic_sum color: #crimson;
    monitor "Node traffic average" value: node_traffic_avg color: #salmon;
  }

}