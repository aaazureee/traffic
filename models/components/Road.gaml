model road
import "./Node.gaml"
import "../Main.gaml"

/** 
 * Road species definition with interactive blocking and unblocking
 * 
 * @author Hieu Chu (chc116@uowmail.edu.au)
 */
species road {
  float link_length; // real world link length distance of the road
  float free_speed; // free flow speed of the road
  int max_capacity; // maximum capcity of road
  int current_volume <- 0; // current volume of road
  float link_full_percentage -> {current_volume / max_capacity}; // percentage of road's fullness to determine status of road
  rgb color; // color of road in main display
  bool blocked <- false; // blocked status of road
  bool hidden <- false;
  string status; // status of current road (low, medium, high, extreme, traffic jammed)
  int accum_traffic_count <- 0; // Accumulated traffic count (number of agents passing through road)

  // user command section
  user_command "Block" action: block;
  user_command "Unblock" action: unblock;
  user_command "View direction" action: view_direction;
  
  /**
   * Interactive block function (Right click selected road -> Apply Block function)
   */
  action block {
    self.blocked <- true; // change blocked status to true
    // regenerate new graph without the edge/road just selected
    my_graph <- directed(as_edge_graph(road where (!each.hidden and !each.blocked)) with_weights (road as_map (each::each.link_length)));
    
    // global switch toggle
    change_graph_action <- true;
    ask people {
      // handle people with smart reroute strategy, their road graph will be updated to discard blocked road too.
      if (modified_graph != nil) {
        if (length(avoided_road) != 0) {
          modified_graph <- directed(as_edge_graph(road where (!(avoided_road contains each) and !each.hidden and !each.blocked)) with_weights (road as_map (each::each.link_length)));
        }
      }
      
      bool exit_flag <- false;
      if (cant_find_path = true) {
        exit_flag <- true;
      }

      if (!exit_flag) {
      // people that are stuck in middle of the road
        if ((self.current_road != nil) and (self.current_road.shape = myself.shape) and (is_on_node = false)) {
          is_in_blocked_road <- true;
        }

        // people that have their next road blocked
        bool next_road_is_blocked <- false;
        if ((self.current_road != nil) and (self.current_road.shape = myself.shape) and (is_on_node = true)) {
          next_road_is_blocked <- true;
        }

        // Only re route for people who has radio or has their next road blocked
        if (is_in_blocked_road = false and (has_radio or next_road_is_blocked)) {
          path new_shortest_path; // new shortest path for comparison
          try {
            new_shortest_path <- path_between(my_graph, location, dest);
          }
          
          // Cannot find shortest path
          catch {
            cant_find_path <- true;
          }

          if (new_shortest_path != nil and new_shortest_path.shape != nil and new_shortest_path.shape.points[length(new_shortest_path.shape.points) - 1] != dest) {
            cant_find_path <- true;
          }
          
          // Update shortest path related variables to travel correctly
          if (cant_find_path = false) {
            if (new_shortest_path = nil or length(new_shortest_path.edges) = 0) {
              cant_find_path <- true;
            } else {
              fixed_edges <- new_shortest_path.edges collect (road(each));
              num_nodes_to_complete <- length(fixed_edges);
              current_road_index <- 0;
              current_road <- fixed_edges[current_road_index];
              shortest_path <- new_shortest_path;
            }

          }
          
          // Handle number of people who cannot find shortest path
          if (cant_find_path and is_on_node) {
            num_people_cant_find_path <- num_people_cant_find_path + 1;
            stuck_same_location <- false;
            speed <- 0 #m / #s;
          }

        }

      }

    }

    // ask people in blocked road and have destination inside blocked road (current road = last road)
    ask people where (each.is_in_blocked_road and (each.current_road_index = (each.num_nodes_to_complete - 1)) and !each.moving_in_blocked_road) {
      moving_in_blocked_road <- true;
      create road {
        shape <- curve(myself.shape.points[0], myself.shape.points[length(myself.shape.points) - 1], curve_width_eff);
        link_length <- myself.current_road.link_length;
        free_speed <- myself.current_road.free_speed;
        max_capacity <- myself.current_road.max_capacity;
        hidden <- true;
      }
      // Since the global graph has the blocked road removed, in order for these people to move in their last road
      // we will assign them a virtual graph with only that road, after finishing this road they will finish their trip      
      mini_graph <- as_edge_graph([road[length(road) - 1]]) with_weights ([road[length(road) - 1]] as_map (each::each.link_length));
      mini_graph <- directed(mini_graph);
    }

    // ask people in blocked road but has destination outside of blocked road 
    // correctly update speed for data stats  
    ask people where (each.is_in_blocked_road and (each.current_road_index != (each.num_nodes_to_complete - 1))) {
      speed <- 0 #m / #s;
    }

  }

  /**
   * Interactive unblock function (Right click selected road -> Apply Unblock function)
   */
  action unblock {
    self.blocked <- false; // change blocked status to false
    // regenerate new graph with the road just unblocked
    my_graph <- directed(as_edge_graph(road where (!each.hidden and !each.blocked)) with_weights (road as_map (each::each.link_length)));

    // global switch toggle
    change_graph_action <- true;
    ask people {
      // handle people with smart reroute strategy, their road graph will be updated to include recently unblocked road too.
      if (modified_graph != nil) {
        if (length(avoided_road) != 0) {
          modified_graph <- directed(as_edge_graph(road where (!(avoided_road contains each) and !each.hidden and !each.blocked)) with_weights (road as_map (each::each.link_length)));
        }
      }
      // people that are in the middle of blocked road will no longer be stuck.
      if (self.current_road != nil and self.current_road.shape = myself.shape and is_on_node = false) {
        is_in_blocked_road <- false;
      }

      // people that are nearby a road that is recently unblocked
      bool next_road_is_unblocked <- false;

      // if agent is on node and that node's location is the starting point of the unblocked road, agent will re-route
      if (self.location = myself.shape.points[0] and is_on_node = true) {
        next_road_is_unblocked <- true;
      }
      
      // Only re route for people who has radio or is near recently unblocked road
      if (is_in_blocked_road = false and (has_radio or next_road_is_unblocked)) {
        bool exit_flag <- false;
        path new_shortest_path; // new shortest path for comparison
        try {
          new_shortest_path <- path_between(my_graph, location, dest);
        }
        
        // Cannot find shortest path
        catch {
          cant_find_path <- true;
          if (is_on_node) {
            speed <- 0 #m / #s;
          }

          exit_flag <- true;
        }
        
        // Cannot find shortest path
        if (new_shortest_path != nil and new_shortest_path.shape != nil and new_shortest_path.shape.points[length(new_shortest_path.shape.points) - 1] != dest) {
          cant_find_path <- true;
        }
        
        // Update shortest path related variables to travel correctly
        if (!exit_flag) {
          if (new_shortest_path = nil or length(new_shortest_path.edges) = 0) {
            cant_find_path <- true;
          } else {
            fixed_edges <- new_shortest_path.edges collect (road(each));
            num_nodes_to_complete <- length(fixed_edges);
            current_road_index <- 0;
            cant_find_path <- false;
            current_road <- fixed_edges[current_road_index];
            shortest_path <- new_shortest_path;
          }

        }
        
        // Handle number of people who cannot find shortest path
        if (cant_find_path and is_on_node) {
          num_people_cant_find_path <- num_people_cant_find_path + 1;
          stuck_same_location <- false;
          speed <- 0 #m / #s;
        }

      }

    }

  }

  /**
   * Helper function to view direction of road
   */
  action view_direction {
    int len <- length(self.shape.points);
    write "source: " + my_node(self.shape.points[0]).node_number + ", dest: " + my_node(self.shape.points[len - 1]).node_number;
  }
  
  aspect base {
    if (link_full_percentage < 0.25) {
      color <- #lime;
      status <- "low";
    } else if (link_full_percentage < 0.5) {
      color <- #blue;
      status <- "moderate";
    } else if (link_full_percentage < 0.75) {
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

    if (!hidden) {
      draw shape color: color width: 3;
    } } }