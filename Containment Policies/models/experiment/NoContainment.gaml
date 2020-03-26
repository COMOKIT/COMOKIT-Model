/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "Abstract.gaml"

global {

	init { 
		do create_authority;
		ask Authority {
			policies << noContainment;
		}

	}

}

experiment "No Containment" parent: "Abstract Experiment" {
	output {
		display "Main" parent: d1 camera_pos: {4148.5899, 11718.8093, 3893.8657} camera_look_pos: {4263.9827, 5107.9567, -1088.3469} camera_up_vector: {0.0105, 0.6017, 0.7986} {
		}

	}

}