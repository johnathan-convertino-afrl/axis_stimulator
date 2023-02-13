# AFRL Simulator Stimulator for AXIS
## AXIS Stimulator modules
---

   author: Jay Convertino   
   
   date: 2022.08.10  
   
   details: AXIS Stimulator, create and write device under test data to and from a file.   
   
   license: MIT   
   
---

![rtl_img](./rtl.png)

### Dependencies
#### Build
  - AFRL:utility:helper:1.0.0
  - AFRL:vpi:binary_file_io:1.0.0
  
#### Simulation
  - AFRL:simulation:clock_stimulator

### IP USAGE
#### INSTRUCTIONS

This core contains two modules. A writer, and reader that should be placed on the  
output, and input of the device under test. This will stream data through till  
is has read all data. Then once all data has been written AND tlast is set to high  
the writer module will end the simulation.

### COMPONENTS
#### SRC

* tm_stim_axis.v
  
#### TB

* tb_axis.v
* test.bin
  
### fusesoc

* fusesoc_info.core created.
* Simulation uses icarus to run data through the core.


