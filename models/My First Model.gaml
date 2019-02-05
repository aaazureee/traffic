/***
* Name: MyFirstModel
* Author: Felt
* Description: My first model?
* Tags: Tag1, Tag2, TagN
***/
model MyFirstModel

global {
  int intA <- 3 min: 0 max: 10 update: intA + 1;
  float floatA <- 3.9;
  string strA <- 'test';
  bool boolA <- true;
  point p <- {0.2, 2.4};
  geometry shape <- square(150 #m);
  graph my_graph;

  init {
  //    write 'Int value:' + intA;
  //    write 'Float value: ' + floatA;
  //    write 'String value: ' + strA;
  //    write 'Boolean value: ' + boolA;
  //    write 'Point co-ordinate: (' + p.x + ',' + p.y + ')';
  //        loop while: true {
  //            write 'dmm';
  //        }
  //        list listWithoutType <- [2, 4.6, "oij", ["hoh", 0.0]];
  //        write length(listWithoutType);
    list result <- [{1, 2}, {3, 4}, {5, 6}];
    //        write (result at 1).x;
    //        list<int> list_int1 <- [1, 5, 7, 6, 7];
    //        list<int> list_int2 <- [6, 9];
    //        list<int> list_int_result <- list_int1 + list_int2;
    //        write list_int_result;
    point var2 <- rnd({2.0, 4.0}, {2.0, 5.0, 10.0}, 1);
    //    write var2;
    //    write shape;
    create my_node {
      location <- {0, 0};
    }

    create my_node {
      location <- {100, 0};
    }

    create road {
      link_length <- 300 #m;
      shape <- line([my_node[0], my_node[1]]);
    }

    my_graph <- as_edge_graph(road) with_weights (road as_map (each::300 #m));
    create people {
      location <- {0, 0};
    }

    step <- 1 #s;
  }

}

species road {
  float link_length;

  aspect base {
    draw shape color: #blue;
  }

}

species people skills: [moving] {
  int a <- 1;
  float ratio <- 1;
  reflex {
    float dis <- 300 #m;
    float free_speed <- 10 #m / #s;
    float time_taken <- (dis / free_speed) #s;
    speed <- 10 #m / #s;
    if (a = 1) {
      ratio <- dis / self distance_to {100, 0} * ratio;
      a <- 0;
    }
    
    
    write "DIST TO GOAL: " + self distance_to {100, 0} * ratio;
    float gama_time <- (self distance_to {100, 0}) / free_speed;
    float true_time <- ((self distance_to {100, 0}) / free_speed) * ratio;
    write "GAMA time: " + gama_time;
    write "TRUE TIME: " + true_time;
    
    write (self distance_to {100, 0}) / free_speed;
    write ratio;
    
    do goto target: {100, 0} on: my_graph;
    write "travelled: " + self distance_to {0, 0};
    //    write "Time: " + time;
    write "Speed: " + speed;
  }

  aspect base {
    draw circle(1.75) color: #purple;
  }

}

species my_node {
  int a <- 5 update: a - 3 min: 0;

  aspect base {
    draw circle(3) color: #yellow;
  }

}

species RANDOM {

  reflex {
    write "test2";
  }

}

experiment my_experiment type: gui {
  output {
    display my_display type: opengl {
      species my_node aspect: base;
      species road aspect: base;
      species people aspect: base;
    }

  }

}



