inputfile1 = "daten/focused-with-fine-grid.cod"--09-09-01-2.cod"
inputfile2 = "daten/focused-with-fine-grid-10mm.cod"--09-09-01-1.cod"
threshold = 180e-7   --minimum number of particles in one pixel to be not neglected
iteration_width = 10 --maximum number of steps between one point of an insula and the next one
relative_hight = 0.5 --relative hight one point must exceed to be counted to the preceding spot
distance = 16        --maximum distance of two matching spots in the two diagramms
displacement = 10    --displacement of the detector in mm.

--FIXME! x and y are puzzled at any place. No idea, where exactly …
--[[ WARNING: if you change the cut_edges, you have to change the threshold, too, to get usefull results!--]]
cut_edges_x1,cut_edges_x2,cut_edges_y1,cut_edges_y2 = 250,100,50,250