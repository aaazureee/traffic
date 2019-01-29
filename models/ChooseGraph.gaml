model graph_model

global {
    int number_of_agents <- 50;
    point source;
    point target;
    graph my_graph;
    path shortest_path;

    init {
        create graph_agent number: number_of_agents;
    }

    reflex pick_two_points {
        if (my_graph = nil) {
            ask graph_agent {
                myself.my_graph <- self.my_graph;
                break;
            }

        }

        shortest_path <- nil;
        loop while: shortest_path = nil {
            source <- point(one_of(my_graph.vertices));
            target <- point(one_of(my_graph.vertices));
            if (source != target) {
                shortest_path <- path_between(my_graph, source, target);
            }

        }

    }

}

species graph_agent parent: graph_node edge_species: edge_agent {
    list<int> list_connected_index;

    init {
        int i <- 0;
        loop x over: graph_agent {
            if (flip(0.1)) {
                add i to: list_connected_index;
            }

            i <- i + 1;
        }

    }

    bool related_to (graph_agent other) {
        using topology: topology(world) {
            return (self.location distance_to other.location < 20);
        }

    }

    aspect base {
        draw circle(2) color: #green;
    }

}

species edge_agent parent: base_edge {

    aspect base {
        draw shape color: #blue;
    }

}

experiment MyExperiment type: gui {
    output {
        display MyDisplay type: java2D {
            species graph_agent aspect: base;
            species edge_agent aspect: base;
            graphics "shortest path" {
                if (shortest_path != nil) {
                    draw circle(3) at: source color: #yellow;
                    draw circle(3) at: target color: #cyan;
                    draw (shortest_path.shape + 5) color: #magenta;
                    write shortest_path.shape;
                }

            }

        }

    }

}