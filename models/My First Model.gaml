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
    create test1 number: 2;
    create road with:[shape: line([test1[0], test1[1]])];
  }

}




species road {
  aspect base {
    draw shape color: #blue;
  }
}

species test1 {
  int a <- 5 update: a - 3 min: 0;
  

  aspect base {
    draw circle(1) color: #yellow;
  }

}

species RANDOM {

  reflex {
    write "test2";
  }

}

experiment my_experiment type:gui{
  output {
    display my_display {
      species test1 aspect: base;
      species road aspect: base;
    }
  }
}



