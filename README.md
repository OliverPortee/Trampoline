
# Trampoline 

Project on a physics based trampoline model, created for my seminar paper at high school (2018-19). It should demonstrate how to mathematically model real world objects. As example question I examine the vertical force on the particle right in the middle (i. e. "dataParticle") which is applied by the surrounding mesh/springs and which dependent on the height of this dataParticle, so how deep the jumping sheet is pushed in. 
This simulation does not aim to be "nice". Its purpose is not to render a beautiful animation. The rendering has only one purpose: to have a visual impression to be abel to control the integrity (can these numbers in the computer *actually* be right?).
Its written in Swift because I love Swift. 

## Basics
The trampoline jumping sheet is modelled as a mesh of particles which are connected with springs. This mesh is a so-called spring mass damper system. This simulation aims to be realistic. It uses physical quantities in "real" units (like metre, seconds, newton, ...).

###Renderer
The Renderer uses metal to render vertices (provided by the mesh) on the screen. It can show the frames in a MTKView or saves them in a movie file.

###Computation
The mesh needs to be updated every frame. Therefore, the program uses a metal kernel shader function to

	1. update the springs (calculate the force on the connected particles) and 
	2. update the particles (calculating acceleration, velocity and new position of each particle based on the applied force).

###Data
The program saves 


##To Do
There is still a lot to do:

	- write update model
	- write data class to save data
	- write dataController which fires when it's time to save new data
	- work on framerate 
	- work on usability: show framerate, show button for non real time rendering, show height and force of dataParticle, button to start/stop the model
	- document program
	


##Sources 
Thanks to [https://github.com/warrenm/MetalOfflineRecording](this) repository! Helped a lot. 