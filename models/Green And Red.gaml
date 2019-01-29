model shortest_path_with_weight

global {
  graph my_graph <- spatial_graph([]);
  path shortest_path;
  list<point> nodes;

  init {
    add point(10.0, 10.0) to: nodes;
    add point(90.0, 90.0) to: nodes;
    add point(40.0, 20.0) to: nodes;
    add point(80.0, 50.0) to: nodes;
    add point(90.0, 20.0) to: nodes;
    loop nod over: nodes {
      my_graph <- my_graph add_node (nod);
    }

    my_graph <- my_graph add_edge (nodes at 0::nodes at 2);
    my_graph <- my_graph add_edge (nodes at 2::nodes at 3);
    my_graph <- my_graph add_edge (nodes at 3::nodes at 1);
    my_graph <- my_graph add_edge (nodes at 0::nodes at 4);
    my_graph <- my_graph add_edge (nodes at 4::nodes at 1);

    // comment/decomment the following line to see the difference.
    my_graph <- my_graph with_weights (my_graph.edges as_map (each::geometry(each).perimeter));
    shortest_path <- path_between(my_graph, nodes at 0, nodes at 1);
    write shortest_path.segments;
  }

}

experiment MyExperiment type: gui {
  output {
    display MyDisplay type: java2D {
      graphics "shortest path" {
        if (shortest_path != nil) {
          draw circle(3) at: point(shortest_path.source) color: #yellow;
          draw circle(3) at: point(shortest_path.target) color: #cyan;
          draw (shortest_path.shape + 1) color: #magenta;
        }

        draw my_graph color: #black;
      }

    }

  }

}