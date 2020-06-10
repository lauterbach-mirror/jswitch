Here are some fully functional example designs for different Lattice FPGAs.
To generate the designs you need to have installed the "Lattice Diamond Software"
or "Lattice iceCube2 Software" depending on the FPGA type.

= Lattice Diamond =
To then generate a design you first of all need to create
  diamond_env.bat            (for Windows)
  diamond_env.sh             (for Linux)

Use diamond_env.bat.sample or diamond_env.sh.sample as basis.

To try out a particular project, open a shell (cmd.exe under Windows, bash under Linux),
change directory into the project you want to generate, then call
   ./0_create_prj.sh         (for Linux)
   .\0_create_prj.bat        (for Windows)

This should setup the project by opening up the "Lattice Diamond Software";
This should also drive the "Lattice Diamond Software" to generate a bit file for programming.

= Lattice iCECube2 =
Generate the project files using
  .\0_create_prj.bat         (for Windows)
  
Open the .project file using iCECube2.
Program the SPI flash using an external programmer of choice.
