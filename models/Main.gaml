model smart_traffic_model

import "./components/Node.gaml"
import "./components/Road.gaml"
import "./components/People.gaml"
import "./components/File Saver.gaml"

global {
  graph my_graph;
  list<point> nodes;
  list<float> time_list; // list of time to arrive to next node;  
  bool change_graph_action <- false;
  float curve_width_eff <- 0.25;
  float seed <- 1.0; // rng seed for reproducing the same result (dev mode);
  file shape_file_roads <- file("../input_data/network_links.shp");
  geometry shape <- envelope(shape_file_roads);
  file strategy_file <- text_file("../input_data/strategies.txt");
  list<float> alpha_arr <- []; // alpha values will be loaded from file (for re-routing strat)
  list<float> theta_arr <- []; // theta values will be loaded from file (for re-routing strat)

  // Category: people related variables
  int nb_people_init <- 50;
  int min_nb_people_spawn <- 10 min: 0 max: 99;
  int max_nb_people_spawn <- 20 min: 0 max: 99;
  int spawn_interval <- 10 min: 0 max: 99;
  float radio_prob <- 0.5 min: 0 max: 1; // probability that a single people agent will have global radio
  float smart_strategy_prob <- 0.51 min: 0 max: 1; // probability that a single people agent will have a smart re-route strategy

  // Category: road density count
  int low_count -> {length(road where (each.status = "low"))};
  int moderate_count -> {length(road where (each.status = "moderate"))};
  int high_count -> {length(road where (each.status = "high"))};
  int extreme_count -> {length(road where (each.status = "extreme"))};
  int traffic_jam_count -> {length(road where (each.status = "traffic_jam"))};

  // Category: road related variables
  int min_capacity_val <- 5;
  int max_capacity_val <- 10;

  // Stats
  list<float> speed_list -> {people collect each.speed};
  map<string, list> speed_histmap -> {distribution_of(speed_list, 10)};
  int nb_people_current -> {length(people)};
  int nb_trips_completed <- 0;
  float avg_speed -> {mean(speed_list)};
  int total_reroute_count <- 0;

  // Stats of people who cant find path      
  list<people> list_people_cant_find_path -> {people where (each.cant_find_path and each.is_on_node and !each.stuck_same_location)}; // acumulated number of people who cant find the shortest path during the simulation
  int num_people_cant_find_path <- 0;

  // Node accumulated traffic count
  list<my_node> top_traffic_nodes -> {my_node sort_by -each.accum_traffic_count};
  int node_accum_traffic_sum -> {sum(top_traffic_nodes collect each.accum_traffic_count)};
  int k_node <- 10 min: 1 max: 20; // top-k populated nodes to display chart

  // Road accumulated traffic count
  list<road> top_traffic_roads -> {road sort_by -each.accum_traffic_count};
  int road_accum_traffic_sum -> {sum(top_traffic_roads collect (each.accum_traffic_count))};
  int k_road <- 10 min: 1 max: 20; // top-k populated roads to display chart

  // orig-dest count
  list<list<int>> orig_dest_matrix;
  bool write_matrix_output <- false;

  init {
  // load road network from shape file
    create road from: shape_file_roads with: [
      name:: "road" + read("ID"), 
      link_length::float(read("length")), 
      free_speed::float(read("freespeed"))
    ];
    ask road {
      shape <- curve(self.shape.points[0], self.shape.points[length(self.shape.points) - 1], curve_width_eff);
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);

      // Create nodes between roads (non-duplicate check)
      point start <- shape.points[0];
      point end <- shape.points[length(shape.points) - 1];
      if (length(my_node overlapping start) = 0) {
        create my_node {
          location <- start;
        }

      }

      if (length(my_node overlapping end) = 0) {
        create my_node {
          location <- end;
        }

      }

    }

    // Load alpha and theta values from file, so when new people are created,
    // they will have a random strategy among the file input
    bool header <- true;
    loop line over: strategy_file {
      if (!header) {
        list<string> split_line <- line split_with ",";
        add float(split_line[0]) to: alpha_arr;
        add float(split_line[1]) to: theta_arr;
      }

      header <- false;
    }

    //    write alpha_arr;
    //    write length(alpha_arr);
    //    write theta_arr;
    //    write length(theta_arr);

    //    ask road {
    //      ask road {
    //        if (myself.shape.points[0] = self.shape.points[length(self.shape.points) - 1] and self.shape.points[0] = myself.shape.points[length(myself.shape.points) - 1] and self !=
    //        myself) {
    //          write string(myself) + " --- " + self;
    //          write myself.shape.points;
    //          write self.shape.points;
    //          write "--------";
    //        }
    //
    //        //        write myself.destruction_coeff; // outer = myself, inner=self.
    //      }
    //
    //    }

    // populate orig dest matrix based on number of nodes
    int max_len <- length(my_node);
    orig_dest_matrix <- list_with(max_len, list_with(max_len, 0));

    // generate graph
    my_graph <- directed(as_edge_graph(road where (!each.hidden)) with_weights (road as_map (each::each.link_length)));

    // init people
    do batch_create_people(nb_people_init);
//    do batch_create_people(10);
    create file_saver number: 1;
    //    write length(people);
  }

  reflex generate_people when: every(spawn_interval) {
//      reflex generate_people when: every(5#cycle) {
    do batch_create_people(min_nb_people_spawn + rnd(max_nb_people_spawn - min_nb_people_spawn));
//        do batch_create_people(5);
  }

  action batch_create_people (int number) {
    if (number = 0) {
      return;
    }
    loop i from: 0 to: number - 1 {
      bool result <- create_people();
      loop while: !result {
        result <- create_people();
      }

    }

  }

  // private helper function
  bool create_people {
    bool result <- true;
    create people {
      int random_origin_index <- rnd(length(my_node) - 1);
      location <- my_node[random_origin_index].location; // CHANGE HERE
      int random_dest_index <- rnd(length(my_node) - 1);
      loop while: random_origin_index = random_dest_index {
        random_dest_index <- rnd(length(my_node) - 1);
      }

      dest <- my_node[random_dest_index].location;
      try {
        shortest_path <- path_between(my_graph, location, dest);
      }

      catch {
        result <- false;
        do die;
      }

      // check for problem with shortest_path when there are no edges connecting a node
      if (shortest_path != nil and shortest_path.shape != nil and (shortest_path.shape.points[0] != location or shortest_path.shape.points[length(shortest_path.shape.points) - 1]
      != dest)) {
        result <- false;
        do die;
      }

      if (cant_find_path = false) {
        if (shortest_path = nil or length(shortest_path.edges) = 0) {
          result <- false;
          do die;
        } else {
        // Fixed road path          
          fixed_edges <- shortest_path.edges collect (road(each));
          num_nodes_to_complete <- length(fixed_edges);
          current_road <- fixed_edges[current_road_index];
          orig_dest_matrix[random_origin_index][random_dest_index] <- orig_dest_matrix[random_origin_index][random_dest_index] + 1;
          result <- true;
          if (has_smart_strategy) {
            int random_strat_index <- rnd(length(alpha_arr) - 1);
            alpha <- alpha_arr[random_strat_index];
            theta <- theta_arr[random_strat_index];
          }

        }

      }

      speed <- 0 #m / #s;
      // increment traffic count at source location node
      my_node(location).accum_traffic_count <- my_node(location).accum_traffic_count + 1;
    }

    return result;
  }

  reflex update_min_time {
    time_list <- [];
    /* Selected people criteria:
     * (
     * Can find the shortest path
     * or Cant find the shortest path but is in the middle of the road (agent will move to the nearest next node before getting stuck)
     * )
     * AND
     * (
     * Is not in the blocked road
     * or Is in the blocked road but the destination is on the same road (other end of the road)
     * )
     */
    list<people> selected_people <- people where ((!each.cant_find_path or (each.cant_find_path and !each.is_on_node)) and ((!each.is_in_blocked_road) or (each.is_in_blocked_road
    and each.current_road_index = each.num_nodes_to_complete - 1)));
    ask selected_people {
      if (self overlaps dest) {
        nb_trips_completed <- nb_trips_completed + 1;
        do die;
      }

      current_road <- fixed_edges[current_road_index];
      int len <- length(current_road.shape.points);
      next_node <- current_road.shape.points[len - 1];
      //      write next_node;
      // current road segment
      float true_link_length <- current_road.link_length; // link length (real_)
      //      write "True link length: " + true_link_length;
      float distance_to_next_node;
      // distance along the curve (must use graph topology because normal distance is euclidean distance
      // i.e. not distance on the curve, which is what we want).
      graph current_graph;
      if (is_in_blocked_road and current_road_index = num_nodes_to_complete - 1) {
      //        write "In updating speed, calculating to minigraph";
        current_graph <- mini_graph;
      } else if (modified_graph != nil) {
        current_graph <- modified_graph;
      } else {
      //        write "Using normal graph";
        current_graph <- my_graph;
      }

      using topology(current_graph) {
        distance_to_next_node <- self distance_to next_node; // gama distance (2d graph)
      }
      //      float distance_to_next_node <- self distance_to next_node; // gama distance (2d graph)
      //      float distance_to_next_node <- topology(current_road) distance_between [self, next_node];
      //      write "next node: " + next_node;
      //      write "GAMA distance: " + distance_to_next_node;
      if (is_road_jammed = true) {
        is_road_jammed <- current_road.current_volume = current_road.max_capacity; // is person stuck?        
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
          if (is_in_blocked_road = false) {
            if (is_on_node) {
              current_road.current_volume <- current_road.current_volume + 1; // increase traffic volume of the road
            }

          }

          free_flow_time_needed <- (distance_to_next_node * ratio) / current_road.free_speed;
        }

        //        write "RATIO: " + ratio;
        real_dist_to_next_node <- distance_to_next_node * ratio;
        float travel_time <- real_dist_to_next_node / speed;
        //        write string(self) + ", speed: " + speed + ", travel time: " + travel_time;
        //        write "Travelled: " + (speed * travel_time);
        //        write "Location: " + location;
        //        write "Real dist to next node: " + real_dist_to_next_node;
        add travel_time to: time_list;
        //        write "//////////////";
      }

    }

    float min_time <- min(time_list);
    ask selected_people {
      step <- min_time;
    }

    ask people {
      real_time_spent <- real_time_spent + min_time;
    }

    if (change_graph_action = true) {
      change_graph_action <- false;
    }

    write "-----------";
  }

  // BPR equation
  float get_equi_speed (float free_speed, int current_volume, int max_capacity) {
    return free_speed / (1 + 0.15 * (current_volume / max_capacity) ^ 4);
  }

  action show_shortest_path {
    geometry circ <- circle(55, #user_location);
    list<people> selected <- people inside circ;
    if (length(selected) > 0) {
      people selected_person <- selected[0];
      ask selected_person {
        if (clicked = true) {
          clicked <- false;
        } else {
          clicked <- true;
        }

      }

    }

  }

}

experiment my_experiment type: gui {
  parameter "Min number people spawn per interval:" var: min_nb_people_spawn category: "People";
  parameter "Max number people spawn per interval:" var: max_nb_people_spawn category: "People";
  parameter "Spawn interval (in cycle):" var: spawn_interval category: "People";
  parameter "Radio probability" var: radio_prob category: "People";
  parameter "Smart strategy probability" var: smart_strategy_prob category: "People";
  parameter "Road network shape file" var: shape_file_roads category: "File";
  parameter "Write matrix output: " var: write_matrix_output category: "File";
  output {
    display main_display type: opengl background: #white {
      species road aspect: base;
      species my_node aspect: base;
      species people aspect: base;
      event [mouse_down] action: show_shortest_path;
    }

    display top_populated_location_chart refresh: every(1 #cycle) {
      chart "Top-" + k_node + " populated nodes (highest accumulated traffic)" type: histogram size: {1, 0.5} position: {0, 0} x_label: "Node id" y_label:
      "Accumulated traffic count" {
        datalist legend: (copy_between(top_traffic_nodes, 0, k_node) collect ("Node " + string(each.node_number))) value: (copy_between(top_traffic_nodes, 0, k_node) collect
        each.accum_traffic_count);
      }

      chart "Top-" + k_road + " populated road (highest accumulated traffic)" type: histogram size: {1, 0.5} position: {0, 0.5} x_label: "Road id" y_label:
      "Accumulated traffic count" {
        datalist legend: (copy_between(top_traffic_roads, 0, k_road) collect (each.name)) value: (copy_between(top_traffic_roads, 0, k_road) collect each.accum_traffic_count);
      }

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
      chart "Average speed series" type: series size: {1, 0.5} position: {0.25, 0} x_label: "Cycle" y_label: "Average speed (m/s)" {
        data "Average speed" value: avg_speed color: #deepskyblue;
      }

//      chart "Speed distribution" type: histogram size: {1, 0.5} position: {0, 0.5} x_label: "Speed bin (m/s)" y_label: "Frequency" {
//        datalist speed_histmap at "legend" value: speed_histmap at "values";
//      }

    }

    monitor "Low density road count" value: low_count color: #lime;
    monitor "Moderate density road count" value: moderate_count color: #blue;
    monitor "High density road count" value: high_count color: #yellow;
    monitor "Extreme density road count" value: extreme_count color: #orange;
    monitor "Traffic jam count" value: traffic_jam_count color: #red;
    monitor "Current number of people" value: nb_people_current;
    monitor "Number of trips completed" value: nb_trips_completed;
    monitor "Average speed" value: avg_speed with_precision 2 color: #deepskyblue;
    monitor "Accumulated node traffic sum" value: node_accum_traffic_sum color: #crimson;
    monitor "Accumulated road traffic sum" value: road_accum_traffic_sum color: #purple;
    monitor "Current list of people who cant find path at unique location" value: list_people_cant_find_path color: #aqua;
    monitor "Accumulated number of people who cant find path" value: num_people_cant_find_path color: #brown;
    monitor "Total reroute count" value: total_reroute_count;
  }

}

