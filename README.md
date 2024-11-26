# AFRL Simulator Stimulator for AXIS
### AXIS Stimulator modules

![image](docs/manual/img/AFRL.png)

---

   author: Jay Convertino   
   
   date: 2022.08.10  
   
   details: AXIS Stimulator, create and write device under test data to and from a file.   
   
   license: MIT   
   
---

### Version
#### Current
  - V1.0.0 - initial release

#### Previous
  - none

### DOCUMENTATION
  For detailed usage information, please navigate to one of the following sources. They are the same, just in a different format.

  - [axis_stimulator.pdf](docs/manual/axis_stimulator.pdf)
  - [github page](https://johnathan-convertino-afrl.github.io/axis_stimulator/)

### DEPENDENCIES
#### Build

  - AFRL:utility:helper:1.0.0
  - AFRL:vpi:binary_file_io:1.0.0
  
#### Simulation
  - AFRL:simulation:clock_stimulator

### COMPONENTS
#### SRC

* tm_stim_axis.v
  
#### TB

* tb_axis.v
  
### FUSESOC

* fusesoc_info.core created.
* Simulation uses icarus to run data through the core. Verification added.

#### Targets

* RUN WITH: (fusesoc run --target=sim VENDER:CORE:NAME:VERSION)
  - default (for IP integration builds)
  - sim
  - sim_rand_data
  - sim_rand_ready_rand_data
  - sim_8bit_count_data
  - sim_rand_ready_8bit_count_data
