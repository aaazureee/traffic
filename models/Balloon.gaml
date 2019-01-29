/***
* Name: Balloon
* Author: Felt
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Balloon

global {
    float worldDimension <- 5.0;
    geometry shape <- square(worldDimension);
    int numBalloonDead <- 0;

    reflex buildBalloon {
        write "attempt to create more balloons";
        create species: balloon number: 1;
    }

    reflex endSimulation when: numBalloonDead > 10 {
        do pause;
    }

}

species balloon {
    float balloonSize;
    rgb balloonColor;

    init {
        write "created";
        balloonSize <- 10 #cm;
        balloonColor <- rgb(rnd(255), rnd(255), rnd(255));
    }

    reflex balloonGrow {
        balloonSize <- balloonSize + 1 #cm;
        if (balloonSize > 50 #cm) {
            if (flip(0.2)) {
                do balloonBurst;
            }

        }

    }

    float balloonVolume (float diameter) {
        return (2 / 3 * #pi * diameter ^ 3) with_precision 3;
    }

    action balloonBurst {
        write "balloon pops!";
        numBalloonDead <- numBalloonDead + 1;
        do die;
    }

    aspect balloonAspect {
        draw circle(balloonSize) color: balloonColor;
        draw string(balloonVolume(balloonSize)) color: #black;
    }

}

experiment testExp type: gui {
    output {
        display myDisplay {
            species balloon aspect: balloonAspect;
        }

    }

}