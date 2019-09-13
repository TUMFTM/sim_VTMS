# sim_VTMS

A framework for the thermal simulation of different vehicle thermal management (VTMS) architectures for electric vehicles.

**Developed at:** [Institute of Automotive Technology](https://www.ftm.mw.tum.de/en/home/), [Technical University of Munich](https://www.tum.de/nc/en/).
**Contact:** [Christoph Reiter](mailto:christoph.reiter@tum.de)


## What does this framework do?

This framework contains a powerful thermal VTMS simulation based on one-dimensional finite elements implemented in Simulink. You can define (almost) any system architecture you desire and the framework will automatically create the Simulink model accordingly. The thermal simulation considers the thermal properties of the coolant used. Therefore, together with the simulation of the mass flow in respect to the coolant pump and branching and union of the volume flow by means of three-way valves and the heat exchange with the drivetrain components and the environment  is able to reproduce the temperatures and heat transport capabilities of a VTMS.

The VTMS simulation is coupled with a longitudinal vehicle simulation and a simulation of the thermal properties of the drivetrain components battery, inverter and electric machine, as well as additional components like charger and experimental components like phase-change materials (PCMs). This allows the definition of different load-cycles and environmental conditions which the framework can use to benchmark different drivetrain and VTMS designs in respect to their impact on component temperatures.

Further information about the modelling approach and the validation of the model can be found in the following publication:

Reiter, Christoph; Dirnecker, Johannes; Lienkamp, Markus (2019): **Efficient Simulation of Thermal Management Systems for BEV**. In: 2019 Fourteenth International Conference on Ecological Vehicles and Renewable Energies (EVER). Monte-Carlo, Monaco, 08.05.2019 - 10.05.2019. IEEE: IEEE, S. 1–8.

DOI: [10.1109/EVER.2019.8813683](https://doi.org/10.1109/EVER.2019.8813683)


## Features

 - Fully automatic VTMS simulation model creation in dependence of the specified VTMS architecture.
 - One dimensional thermal fluid simulation within the VTMS considering type of fluid, mass flow, diameters, branching and union of the volume flow
 - Simple control logic to control coolant pumps, three-way valves and radiator fans in the system
 - Consideration of all thermal energy flows from and to the system by means of component waste heat, heat-exchangers between different coolant cycles and radiators to exchange heat with the environment
 - Efficiency map based thermal drivetrain component simulation coupled with a longitudinal dynamics simulation allowing any desired load-cycle (velocity and charging power), ambient temperatures and vehicle parameters (mass, drag coefficients and so on)
 - Script based simulation to automatically test a high number of different scenarios

Note: 
- This framework is considered as feature complete in the scope of the project it's currently used in. So don't expect any big updates apart from bug-fixes, cosmetic work and improvement of documentation. 
- The framework has yet to undergo final testing so be careful with the results!


## Validation of the framework

See our paper cited above. The results cannot be shown here due to copyright restrictions.


## Use and expansion of the framework

We are very happy is you choose this framework for your projects and research! We are looking forward to hear your feedback and kindly ask you to share bugfixes, improvements and updates in this repository.

**Please cite the if you use the framework for your publications!**

The model is released under the GNU LESSER GENERAL PUBLIC LICENSE Version 3 (29 June 2007). Please refer to the license file for any further questions about incorporating this framework into your projects.


## Requirements


### Matlab

The model was created with **MATLAB 2018b**. If you want to commit an updated version using another toolbox please give us a short heads-up. 

Required Toolboxes:
- Simulink 9.2
- DSP Systems Toolbox 9.7
- Embedded Coder 7.1 _(if "Accelerator" is used in Simulink)_
- Simulink Coder 9.0 _(if "Accelerator" is used in Simulink)_
- Parallel Computing Toolbox 6.13 _(if more than one processor core should be used)_

The insitute usually follows the 'b' releases of Mathworks, so the framework may get updated to 2019b in the future.


### Other open-source software

The electrical and thermal simulation on the cell level build upon a simplified version of the Simulink framework **[sim_battery_system](https://github.com/TUMFTM/sim_battery_system)** by some of the same authors and also created at  [Institute of Automotive Technology](https://www.ftm.mw.tum.de/en/home/). Everything needed is already included in this repository.

The the physical fluid properties are derived by the open source framework **[CoolProp](http://www.coolprop.org/)**. We thank the authors of CoolProp for their work! If you want to use this framework as well you must comply to their [licence conditions](http://www.coolprop.org/index.html#license-information).

**You must provide the required CoolProp data yourself. Refer to the information in the folder _coolprop_ in the simulation framework.**



## How To Use


### Disclamer

All parameters in this release are for debugging and testing purposes only and have nothing to do with the real world. Use at your own risk! **To get valid results out of this framework you have to provide your own data!**


### Basic steps

-  All the individual steps get called from the script *main_sim_VTMS.m* and also are thorougly documented there.
- To provide you own parameters first go to *main_sim_VTMS.m* afterwars fill in the information needed in the folders *01_vehicles*, *02_driving_cycles* and *03_VTMS_architectures*. Sample data is already provided.
- Run *main_sim_VTMS.m* and the simulation starts. The command window shows the current simulation count and the total number of simulations as well as the time required for each simulation run.


### Definition of new VTMS architectures

This is possible the hardest part of adapting the model. The framework used the [`digraph`](https://de.mathworks.com/help/matlab/ref/digraph.html) feature of MATLAB to define what components are part of the VTMS and how they are connected.  

There are already seven different VTMS architectures defined in the framework right now in *03_VTMS_architectures*. They are shown below as an example and are a good start if you want to adapt the architectures to your own needs. General VTMS definitons are found in the file *general_VTMS_parameters.m*.

The architectures already defined get more and more complex, so we will use them to explain the logic behind the architecture definitions. 

All pictures below are from the thesis *Konzeptentwicklung, Auslegung und Bewertung von Thermomanagementsystemen für elektrische Antriebsstränge* by [Felix Näher](felix.naeher@web.de).


#### VTMS Type 1

![Structure of VTMS Type 1](/pics/VTMS_type_1.png)

File: *fun_sim_VTMS_type_1.m*

Code for definition: 

    Konfig_Kuehlkreislauf{1} = {{'Fluid_Ladegeraet(1)','Fluid_Schlauch(1)','Fluid_Leistungselektronik(1)','Fluid_Schlauch(2)','Fluid_EMaschine(1)','Fluid_Schlauch(3)','Fluid_Kuehler(1)','Fluid_Schlauch(4)'} 
                               [1,2,3,4,5,6,7,8]                       
                               [2,3,4,5,6,7,8,1]};

A very simple loop with only the tree components **charger** (=*Ladegeraet*), **inverter** (=*Leistungselektronik* or *LE*) and **electric machine** (=*EMaschine* or *EM*). Between each of those components is a **pipe** (=*Schlauch*). Also there is one **radiator** (=*Kuehler*). 

Because we only have one loop (=*Kuehlkreislauf*) we only need one cell array `Konfig_Kuehlkreislauf`. All components **that are part of the loop** are specified in the first cell array within `Konfig_Kuehlkreislauf`. The components must use the name scheme used in the example and are numbered. In the example we have more that one pipe, so there exists a `'Fluid_Schlauch(2)'`  
The second and third array with in the cell array describe with components are connected to each other. The numbers corresponds to the position of the component in the first cell array. In our example the first entry in the cell array `'Fluid_Ladegeraet(1)'` is connected to the second one `'Fluid_Schlauch(1)'` as specified by the first elements of the second and third array. Refer to the documentation for [`digraph`](https://de.mathworks.com/help/matlab/ref/digraph.html) to learn more about about the logic behind this.
Note that the **battery** (=*Battery*) doesn't show up in this definition because it is not part of the VTMS. Of course it will get simulated as well, but it won't interact with the VTMS and therefore also won't get cooled. Also note that the pump is not part of the definition. Every coolant loop has a uniform volume flow to the position of the pump within the loop is irrelevant and it doesn't need to be placed.


#### VTMS Type 2

![Structure of VTMS Type 2](/pics/VTMS_type_2.png)

File: *fun_sim_VTMS_type_2.m*

Code for definition: 

    Konfig_Kuehlkreislauf{1} = {{'Fluid_Batteriepack(1)','Fluid_Schlauch(1)','Fluid_Ladegeraet(1)','Fluid_Schlauch(2)','Fluid_Leistungselektronik(1)','Fluid_Schlauch(3)','Fluid_EMaschine(1)','Fluid_Schlauch(4)','Fluid_Kuehler(1)','Fluid_Schlauch(5)'} 
                               [1,2,3,4,5,6,7,8, 9,10]
                               [2,3,4,5,6,7,8,9,10, 1]};

Like VTMS Type 1, but now the battery system (=*Batteriepack*) is included and `'Fluid_Batteriepack(1)'` shows up in the definition.

#### VTMS Type 3

![Structure of VTMS Type 3](/pics/VTMS_type_3.png)

File: *fun_sim_VTMS_type_3.m*

Code for definition: 

    Konfig_Kuehlkreislauf{1} = {{'Fluid_Ladegeraet(1)','Fluid_Schlauch(1)','Fluid_Leistungselektronik(1)','Fluid_Schlauch(2)','Fluid_EMaschine(1)','Fluid_Schlauch(3)','Fluid_Kuehler(1)','Fluid_Schlauch(4)'} 
                               [1,2,3,4,5,6,7,8]
                               [2,3,4,5,6,7,8,1]};
                          
    Konfig_Kuehlkreislauf{2} = {{'Fluid_Batteriepack(1)','Fluid_Schlauch(5)','Fluid_Schlauch(6)','Fluid_Schlauch(7)','Fluid_Schlauch(8)','Fluid_Kuehler(2)','Fluid_Schlauch(9)'} 
                               [1,2,3,4,2,5,6,7]
                               [2,3,4,1,5,6,7,4]};     

Now it starts to get complicated. Now we have a high and a low temperature loop. Because of this we need a `Konfig_Kuehlkreislauf{2}` . Within `Konfig_Kuehlkreislauf{2}` we have another new feature. At **V** the volume flow is split, at **V'** there is a union. This desciptes a **three-way-valve** (=*Dreiwegeventil*). Note how the second element `'Fluid_Schlauch(5)'` is in contact with *two* other components (`'Fluid_Schlauch(6)'` and `'Fluid_Schlauch(8)'`). The ratio of how much fluid is going to each of the two pipes behind the three-way-valve can be defined by a look-up-table depended on the fluid temperature or set to a fixed value.

#### VTMS Type 4

![Structure of VTMS Type 4](/pics/VTMS_type_4.png)

File: *fun_sim_VTMS_type_4.m*

Code for definition: 

    Konfig_Kuehlkreislauf{1} = {{'Fluid_Ladegeraet(1)','Fluid_Schlauch(1)','Fluid_Leistungselektronik(1)','Fluid_Schlauch(2)','Fluid_EMaschine(1)','Fluid_Schlauch(3)','Fluid_Kuehler(1)','Fluid_Schlauch(4)'}
                               [1,2,3,4,5,6,7,8]
                               [2,3,4,5,6,7,8,1]};

    Konfig_Kuehlkreislauf{2} = {{'Fluid_Batteriepack(1)','Fluid_Schlauch(5)','Fluid_Schlauch(6)','Fluid_Schlauch(7)','Fluid_PCM(1)','Fluid_Schlauch(8)','Fluid_Schlauch(9)','Fluid_Kuehler(2)','Fluid_Schlauch(10)'}
                               [1,2,3,4,5,6,2,7,8,9]
                               [2,3,4,5,6,1,7,8,9,4]};   

Like VTMS Type 3 but with an additional phase change material (PCM) heat buffer in `Konfig_Kuehlkreislauf{2}`.

#### VTMS Type 5

![Structure of VTMS Type 5](/pics/VTMS_type_5.png)

File: *fun_sim_VTMS_type_5.m*

Code for definition: 

    Konfig_Kuehlkreislauf{1} = {{'Fluid_Ladegeraet(1)','Fluid_Schlauch(1)','Fluid_Leistungselektronik(1)','Fluid_Schlauch(2)','Fluid_EMaschine(1)','Fluid_Schlauch(3)','Fluid_Waermetauscher(1,1)','Fluid_Schlauch(4)','Fluid_Kuehler(1)','Fluid_Schlauch(5)'} 
                               [1,2,3,4,5,6,7,8, 9,10]
                               [2,3,4,5,6,7,8,9,10, 1]};

    Konfig_Kuehlkreislauf{2} = {{'Fluid_Batteriepack(1)','Fluid_Schlauch(6)','Fluid_Schlauch(7)','Fluid_Waermetauscher(2,1)','Fluid_Schlauch(8)','Fluid_Schlauch(9)','Fluid_Schlauch(10)','Fluid_Kuehler(2)','Fluid_Schlauch(11)'}
                               [1,2,3,4,5,6,2,7,8,9]
                               [2,3,4,5,6,1,7,8,9,6]};  

Also based on VTMS Type 3 but now the two coolant loops are thermally connected by a **heat-exchanger** (=*Waermetauscher*). Note that the heat-exchanger is defined by two numbers: `'Fluid_Waermetauscher(1,1)'` and `'Fluid_Waermetauscher(2,1)'`. The last number is the index of the heat exchanger in the system (we have one). The first number is the index of the coolant loops interacting in this heat-exchanger.


#### VTMS Type 6

![Structure of VTMS Type 6](/pics/VTMS_type_6.png)

File: *fun_sim_VTMS_type_6.m*

Code for definition: 

    Konfig_Kuehlkreislauf{1} = {{'Fluid_Ladegeraet(1)','Fluid_Schlauch(1)','Fluid_Leistungselektronik(1)','Fluid_Schlauch(2)','Fluid_EMaschine(1)','Fluid_Schlauch(3)','Fluid_Waermetauscher(1,1)','Fluid_Schlauch(4)','Fluid_Kuehler(1)','Fluid_Schlauch(5)'}  
                               [1,2,3,4,5,6,7,8, 9,10]
                               [2,3,4,5,6,7,8,9,10, 1]};

    Konfig_Kuehlkreislauf{2} = {{'Fluid_Batteriepack(1)','Fluid_Schlauch(6)','Fluid_Schlauch(7)','Fluid_Waermetauscher(2,1)','Fluid_Schlauch(8)','Fluid_Schlauch(9)','Fluid_PCM(1)','Fluid_Schlauch(10)','Fluid_Schlauch(11)','Fluid_Kuehler(2)','Fluid_Schlauch(12)'} 
                               [1,2,3,4,5,6,7,8,2, 9,10,11]
                               [2,3,4,5,6,7,8,1,9,10,11, 6]}; 
 
 Nothing new compared to VTMS Type 6, just added some PCM.
  


#### VTMS Type 7

![Structure of VTMS Type 7](/pics/VTMS_type_7.png)

File: *fun_sim_VTMS_type_7.m*

Code for definition: 

    Konfig_Kuehlkreislauf{1} = {{'Fluid_Ladegeraet(1)','Fluid_Schlauch(1)','Fluid_Leistungselektronik(1)','Fluid_Schlauch(2)','Fluid_EMaschine(1)','Fluid_Schlauch(3)','Fluid_Waermetauscher(1,1)','Fluid_Schlauch(4)','Fluid_Kuehler(1)','Fluid_Schlauch(5)'}  
                               [1,2,3,4,5,6,7,8, 9,10]
                               [2,3,4,5,6,7,8,9,10, 1]};

    Konfig_Kuehlkreislauf{2} = {{'Fluid_Batteriepack(1)','Fluid_Schlauch(6)','Fluid_Schlauch(7)','Fluid_Schlauch(8)','Fluid_Waermetauscher(2,1)','Fluid_Schlauch(9)','Fluid_Schlauch(10)','Fluid_Schlauch(11)','Fluid_Schlauch(12)','Fluid_Kuehler(2)','Fluid_Schlauch(13)','Fluid_Schlauch(14)','Fluid_Waermetauscher(1,2)','Fluid_Schlauch(15)'} 
                               [1,2,3,4,5,6,7,8,3, 9,10,11, 2,12,13,14]                                         
                               [2,3,4,5,6,7,8,1,9,10,11, 7,12,13,14, 8]};                      

    Konfig_Kuehlkreislauf{3} = {{'Fluid_PCM(1)','Fluid_Schlauch(16)','Fluid_Waermetauscher(2,2)','Fluid_Schlauch(17)'}
                               [1,2,3,4]
                               [2,3,4,1]};

The most complex structure. Now we have three coolant loops and two heat exchangers. Also is not `Konfig_Kuehlkreislauf{2}` split up one but twice. Maybe you have noted that we have only talked about coolant loops as of now. The framework cannot simulation the phase change of refrigerant loops, but there is a workaround. In `Konfig_Kuehlkreislauf{3}` we use a PCM with infinite heat capacity which allows us to set the temperature of this loop to a temperature a refrigerant loop would have.


## Authors and Maintainers

- [Christoph Reiter](mailto:christoph.reiter@tum.de)
	- Idea, structure, underlying concepts and algorithms except where noted otherwise.
	- Supervision of the underlying student's theses.
	- Final implementation, revision and benchmarking.


## Contributions

- [Johannes Dirnecker](johannes.dirnecker@gmx.net)
	- Initial implementation in MATLAB/Simulink
	- Development of the finite volume simulation and implementation of the automatic model setup.
	- Research of theoretical background of thermal VTMS simulation
	- Basic validation of the algorithm as part of his master's thesis
- [Benno Bernhardt](benno.bernhardt@outlook.de)
	- Implementation of PCM
	- Implementation of reversible fluid flow
	- Contributions to the determination of thermal parameters as part of his master's thesis
- [Felix Näher](felix.naeher@web.de)
	- Implementation of the different load-scenarios and the automatic simulation
	- Development and implementation of the different VTMS architectures as part of his term project
 - Christian Schötz
	- Initial development of the thermal component models as part of his master's thesis

