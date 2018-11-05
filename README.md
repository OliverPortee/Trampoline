
# Trampoline 

Project on a physics based trampoline model, created for my seminar paper at high school (2018-19). It should demonstrate how to mathematically model real world objects. As example question I examine the vertical force on the particle right in the middle (i. e. "dataParticle") which is applied by the surrounding mesh/springs and which dependent on the height of this dataParticle, so how deep the jumping sheet is pushed in.

This simulation does not aim to be "nice". Its purpose is not to render a beautiful animation. The rendering has only one purpose: to have a visual impression to be abel to control the integrity (can these numbers in the computer *actually* be right?).

Its written in Swift because I love Swift. I'm still an absolute beginner, though.

## How it works
The trampoline jumping sheet is modelled as a mesh of particles which are connected with springs. This mesh is a so-called spring mass damper system. This simulation aims to be realistic. It uses physical quantities in "real" units (like metre, seconds, newton,...).

### Renderer
The Renderer uses metal to render vertices (provided by the mesh) on the screen. It can show the frames in a MTKView or saves them in a movie file.

### Computation
The mesh needs to be updated every frame. Therefore, the program uses a metal kernel shader function to

1. update the springs (calculate the force on the connected particles) and 
2. update the particles (calculating acceleration, velocity and new position of each particle based on the applied force).

### Data
The program saves force and height of the data particle in a DoubleData instance. This data can be written to a file and the python script can be used to display a graph from matplotlib. 


## To Do
There is still a lot to do:

- control springconstants of outer springs (they seem inconsistent) 
- synchronisation with ui at the beginning (mesh paramters from sliders)
- get triple buffering and in flight semaphore right
- real time rendering
- make UI and Unit Tests
	
## Sources 
Thanks to [this](https://github.com/warrenm/MetalOfflineRecording) repository! Helped a lot. 
