/***
* Name: regularspecies
* Author: Felt
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model display_one_agent

global {
//  geometry shape <- square(1000 #m);
  graph the_graph;

  init {
    create dogSpec {
      dog <- 100;
    }

    create dogSpec {
      dog <- 150;
    }

    create dogSpec {
      dog <- 999;
    }

    create road {
      shape <- line([{0, 30}, {100, 30}]);
    }

    map<road, float> weight_map <- road as_map (each::each.shape.perimeter);
    the_graph <- as_edge_graph(road) with_weights weight_map;
    create myCircle {
      dog <- 0;
      location <- {30, 30};
    }

    create myCircle {
      dog <- 1;
      location <- {50, 30};
    }

  }

  reflex {
    loop x over: road {
      list<myCircle> testL <- agents_inside(x);
      loop c over: testL {
        write c.dog;
      }

    }

    //    loop y over: myCircle {
    //      write y;
    //    }
    //    if (cycle = 2) {
    //      write "ORDER";
    //      loop x over: dogSpec {
    //        write x.dog;
    //      }
    //
    //    }

  }

}

species dogSpec {
  int dog;

  //  reflex {
  //    write dog;
  //  }
  aspect standard_aspect {
    draw geometry: circle(1 #m);
  }

}

species road {
  int dog <- 5;
  int cat <- 10;

  aspect base {
    draw shape color: #blue;
  }

}

species myCircle skills: [moving] {
  int dog;
  float speed <- 100 #m / #s;

  aspect base {
    draw circle(5 #m) color: #red;
  }

  reflex {
    write "HERE " + dog;
  }

  //  reflex {
  //    do goto target: {1000, 0} on: the_graph;
  //  }

}

experiment my_experiment type: gui {
  output {
    display myView type: opengl {
      species road aspect: base;
      species myCircle aspect: base;
    }

  }

}

