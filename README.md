# hollow_circle
personal project. rendering a hollow circle.

simple project i wanted to do in order to see how efficient i could do graphics. Spent much time on looking for ways to make it faster. Ultimately, I accepted that its realistically possible for me to be able to render my hollow circle in the theoretically most efficient way. Windows complicates things. The best thing to do would be to use opengl, but i avoided doing that because the point was to do everything on my own. I wanted to handle EVERYTHING. 

# v8

notes:
	- trying to use direct 3d to make things better. the most direct pipeline (right after rendering with cuda, swap a pointer, or at least copy it only once from current memory to the memory space of the window, for the Windows Compositor to use.) unfortunately is not an option. Windows makes things hard. What do you expect from a backwards-compatible operating system born in the 1900's.
	- GDI is what the last backup of my project used, and it is TERRIBLE. theres like 3 copies of all the data going on. gpu to cpu, my memory to gdi memory, gdi memory to gpu, or something like that). its SO unnecessary. Its unbelievable that this is a WINDOWS thing. WINDOWS EXPECTS YOU to use GDI, which requires you to COPY PIXEL DATA instead of just GIVING them a pointer to your pixel data.