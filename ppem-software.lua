--[[=== software for evaluating the ppem-tests ===--
Send any suggestions or comments to arno.trautmann@gmx.de.

overall action:
data file is read (inputfile)
change as there will be two input data files per run!

variables to set:
for each set of data, the following things have to be adjusted (user interface):
– inputfile
– gridfile (see above/below)
– threshold (controls the background)
– iteration_width (steps in a spot)
– distance (between matching spots in 1st and 2nd data set)
– displacement (of the detector in mm)
– cut_edges (used to cut off nasty edges or concentrate on the important area)

If cut_edges does not satisfy you, because you need to cut off different amounts on each side, go to function estimate_maxima and set the corresponding sides one by one.

Stack overflow in function 'scan_island' means there are no isolated spots, but everything is counted into one spot. Higher the threshold to get usefull results!

*todo*
graph_factor1 and 2 are only empirical. Not critical, but they should be calculatable!!
--]]


--global variables, only initialization.
xmax,ymax = 0,0

--”user interface“
require("userinterface")

--file to give a beautiful output
require("writetexfile")

--file with small, but usefull helpers
require("helperfunctions")

insulae = {}

insula_index = 1
insula_subindex = 1

x_middle = {}   --array for spots (x)
y_middle = {}   --array for spots (y)
particles = {}  --array for spots (№ of particles in that spot)
n = 0           --total № of particles

x_middle1 = {} y_middle1 = {} particles1 = {}
x_middle2 = {} y_middle2 = {} particles2 = {}

--calculates the number of points in each direction by assuming symmetric values (e.g. +/- 2000), considering the next value (e.g. 1995), calculating the difference (5) and thus gets the total number (800+1 for the 0 value). Works both for integer as well as values in cm/mm.
function estimate_maxima(file)
  io.input(io.open(file))
  x_one = io.read("*number")
print("Erster x-Wert = "..x_one)
  tmp = io.read()
  x_two = io.read("*number")
print("Zweiter x-Wert = "..x_two)
  io.input(close)
  steps = math.ceil(2*x_one / (x_one-x_two) + 1)

  xmax,ymax = steps,steps
  print("Daten liegen in "..steps.." Schritten vor.")

  y_min = cut_edges_y1 --actually x
  y_max = ymax - cut_edges_y2
  x_min = cut_edges_x1 --actually y
  x_max = xmax - cut_edges_x2
end

-- prepares a temporary file with the cut edges. The first run will take much time, but the next run will be much shorter because the field does not need to be prepared again.
function cut_borders(file)
print("Hilfsdatei für diese Ränder wird erstellt.\n Dies kann einige Zeit in Anspruch nehmen!\n Name der Hilfsdatei:"..file.."_cut_"..cut_edges_x1.."-"..cut_edges_x2.."-"..cut_edges_y1.."-"..cut_edges_y2)
  totalnumbers = 0

  io.input(file)
  tmpline = {}
  for x = 1,xmax do
  tmpline[x] = {}
    for y = 1,ymax do
      tmpline[x][y] = string.sub(io.read(),-14,-1)
      totalnumbers = totalnumbers + tmpline[x][y]
    end
  end
  io.input(close)
print("Originaldaten gelesen und in Variable tmpline gespeichert.")
  io.output(io.open(file.."_cut_"..cut_edges_x1.."-"..cut_edges_x2.."-"..cut_edges_y1.."-"..cut_edges_y2,"w"))
  for x = 1,xmax do
    for y = 1,ymax do
        if ((x > x_min) and (x < x_max) and (y > y_min) and (y < y_max)) then
          io.write(tmpline[x][y].."\n")
        else
        end
      end
    end
  io.write(totalnumbers)
  io.close()
end

--reads the field from the helper file (with the "_cut_") in it
function read2dfrom1d(file)
  field = {}
  for x = 1,xmax do
    field[x] = {}
  end

  for x = 1,x_min do
      for y = 1,ymax do
        field[x][y] = 0
      end
  end
  for x = x_max,xmax do
      for y = 1,ymax do
        field[x][y] = 0
      end
  end
  for x = 1,xmax do
    for y = 1,y_min do
      field[x][y] = 0
    end
    for y = y_max,ymax do
      field[x][y] = 0
    end
  end

  io.input(file)
  for x = x_min+1,x_max-1 do
    for y = y_min+1,y_max-1 do
      templine = io.read()
      field[x][y] = tonumber(templine) --read the last 13 chars, ignoring eol-char
    end
  end
  totalnumber = io.read()
  io.input(close)

  return field,totalnumber
end

--normalizes the field so that the total number = 1
--enables the same threshold for both datafiles
function normalize_field(field,total)
  normalized_field = {}
  for x = x_min,x_max do
    normalized_field[x] = {}
    for y = y_min,y_max do
      normalized_field[x][y] = field[x][y] / total
    end
  end
  return normalized_field
end

--cuts off the border to avoid edge-effects and destroys all data that are under the threshold
function cut_border_and_threshold(field)
  returnfield = {}
  for x = 1,xmax do
    returnfield[x] = {}
    for y = 1,ymax do
      if (x < x_min) or (x > x_max) or (y < y_min) or (y > y_max) then
        returnfield[x][y] = 0
      else
        if field[x][y] > threshold then
          returnfield[x][y] = field[x][y] - threshold
        else
          returnfield[x][y] = 0
        end
      end
    end
  end
  return returnfield
end

--scans for insulae in insulafield to find the peaks
function scan_for_insulae()
  insula_index = 0
  for x = 1,xmax do
    for y = 1,ymax do
      if insulafield[x][y] > 0 then    --find anything above the threshold
        insula_index = insula_index + 1  --find the next insula
        insulae[insula_index] = {}       --make an array for all the points in this island
        insula_subindex = 1
        scan_island(x,y)
      end
    end
  end
end

function test_next_point(headnumber,newx,newy)
  if insulafield[newx][newy] > relative_hight*headnumber then
    scan_island(newx,newy)
  end
end

--helper function:
--tries to find all members of a single island
--if trigger is too low, will raise an error when hitting the edes!
function scan_island(x,y)
  if insulafield[x][y] > 0 then
    tempval = insulafield[x][y]

    insulae[insula_index][insula_subindex] = {}
    insulae[insula_index][insula_subindex][1] = x
    insulae[insula_index][insula_subindex][2] = y
    insulae[insula_index][insula_subindex][3] = tempval

    insulafield[x][y] = 0                --got it, set it to 0 so it won’t be scanned again
    insula_subindex = insula_subindex +1 --next item gets to the next entry of this insula

    for i = 1,iteration_width do
      for j = 1,iteration_width do
        test_next_point(tempval,x-i,y)
        test_next_point(tempval,x-i,y+j)
        test_next_point(tempval,x-i,y-j)
        test_next_point(tempval,x,y+j)
        test_next_point(tempval,x+i,y+j)
        test_next_point(tempval,x+i,y)
        test_next_point(tempval,x+i,y-j)
      end
    end
  end
end

--calculates the weights of each spot
function determine_spot_positions()
  x_tmp = 0; y_tmp = 0               --for the calculation of <x²>, <y²>
  x_tmp_square = 0; y_tmp_square = 0 --for the calculation of <x²>, <y²>

  for i = 1,#insulae do
    x_middle[i] = 0; y_middle[i] = 0; particles[i] = 0

    --calculate the weighted middle of the spot
    for j = 1,#insulae[i] do
      x_middle[i] = x_middle[i] + insulae[i][j][1]*insulae[i][j][3]
      y_middle[i] = y_middle[i] + insulae[i][j][2]*insulae[i][j][3]
      particles[i] = particles[i] + insulae[i][j][3]
    end

    x_middle[i] = x_middle[i] / particles[i]  --all points of one spot get this x-value
    y_middle[i] = y_middle[i] / particles[i]  --all points of one spot get this y-value

    n = n + particles[i]

    x_tmp_square = x_tmp_square + x_middle[i]*x_middle[i]
    y_tmp_square = y_tmp_square + y_middle[i]*y_middle[i]
    x_tmp = x_tmp + x_middle[i]
    y_tmp = y_tmp + y_middle[i]
  end
end

-- searches for matching points from both data sets. If the spots are not further away than "distance", they are considered to match.
function match_spots()
  spots_not_matched = {}
  spot_x = {}
  spot_dx = {}
  spot_y = {}
  spot_dy = {}
  particles = {}
  k = 0
  for i = 1,#x_middle1 do
    found_matching = false
    for j = 1,#x_middle2 do
      -- if the distance between two spots is smaller than "distance", they belong to each other. counter of 2 is adopted.
      if math.abs(x_middle1[i]-x_middle2[j]) < distance and math.abs(y_middle1[i]-y_middle2[j]) < distance then
        tmp_x = x_middle2[j]
        tmp_y = y_middle2[j]
        tmp_part = particles2[j]
        x_middle2[j] = x_middle2[i]
        y_middle2[j] = y_middle2[i]
        particles2[j] = particles2[i]
        x_middle2[i] = tmp_x
        y_middle2[i] = tmp_y
        particles2[i] = tmp_part

        k = k+1
        spot_x[k] = x_middle1[i]
        spot_dx[k] = (x_middle1[i] - x_middle2[i])/displacement
        spot_y[k] = y_middle1[i]
        spot_dy[k] = (y_middle1[i] - y_middle2[i])/displacement
        particles[k] = particles1[i]

        found_matching = true
      end
    end
    if not(found_matching) then
      table.insert(spots_not_matched,i)
    end
  end
print("Spots not matched: ",#spots_not_matched)
print("Number of matched spots: "..#spot_x)
  io.output(io.open("phase_space_diagramm_x","w"))
  for i = 1,#spot_x do 
    io.write(spot_x[i].." "..spot_dx[i].." "..particles[i].."\n")
  end
  io.close()

  io.output(io.open("phase_space_diagramm_y","w"))
  for i = 1,#spot_y do 
    io.write(spot_y[i].." "..spot_dy[i].." "..particles[i].."\n")
  end
  io.close()
end

-- calculates the rms emittance x and y.
function calculate_emittance()
  total = 0
  x_bar = 0 dx_bar = 0
  y_bar = 0 dy_bar = 0
  for i = 1,#spot_x do
    total = total + particles[i]
    x_bar = x_bar + particles[i]*spot_x[i]
    y_bar = y_bar + particles[i]*spot_y[i]
    dx_bar = dx_bar + particles[i]*spot_dx[i]
    dy_bar = dy_bar + particles[i]*spot_dy[i]
  end
  x_bar = x_bar / total
  y_bar = x_bar / total
print("xbar = ",x_bar)
print("ybar = ",y_bar)
print("dxbar = ",dx_bar)
print("dybar = ",dy_bar)
  sum_x = 0 sum_dx = 0 sum_x_dx = 0
  sum_y = 0 sum_dy = 0 sum_y_dy = 0
  for i = 1,#spot_x do
    sum_x = sum_x + (spot_x[i]*particles[i] - x_bar)^2
    sum_y = sum_y + (spot_y[i]*particles[i] - y_bar)^2
    sum_dx = sum_dx + (spot_dx[i]*particles[i] - dx_bar)^2
    sum_dy = sum_dy + (spot_dy[i]*particles[i] - dy_bar)^2
    sum_x_dx = sum_x_dx + (spot_x[i]*particles[i] - x_bar)*(spot_dx[i]*particles[i] - dx_bar)
    sum_y_dy = sum_y_dy + (spot_y[i]*particles[i] - y_bar)*(spot_dy[i]*particles[i] - dy_bar)
  end
  x_sq = sum_x / total
  y_sq = sum_y / total
  dx_sq = sum_dx / total
  dy_sq = sum_dy / total
  x_dx = sum_x_dx / total
  y_dy = sum_y_dy / total
  rms_emitt_x = math.sqrt(x_sq*dx_sq - (x_dx)^2)
  rms_emitt_y = math.sqrt(y_sq*dy_sq - (y_dy)^2)
print("emittance x",rms_emitt_x)
print("emittance y",rms_emitt_y)
end

function process_file(file)
  local tmpfile = io.open(file.."_cut_"..cut_edges_x1.."-"..cut_edges_x2.."-"..cut_edges_y1.."-"..cut_edges_y2)
  if tmpfile then
    io.close(tmpfile)
  else
  print("Hilfsdatei ("..file.."_cut_"..cut_edges_x1.."-"..cut_edges_x2.."-"..cut_edges_y1.."-"..cut_edges_y2..") existiert nicht!")
    cut_borders(file)
  end

  --read the datafile
  mainfield,total = read2dfrom1d(file.."_cut_"..cut_edges_x1.."-"..cut_edges_x2.."-"..cut_edges_y1.."-"..cut_edges_y2)
  --normalize the data – sum = 1
  mainfield = normalize_field(mainfield,total)
  --cut off the borders (eliminate edge-effects)
  insulafield = cut_border_and_threshold(mainfield)

  --scans for isolated areas. That will be the spots we’re looking for!
  scan_for_insulae()

  determine_spot_positions()
end

--Die Hauptfunktion, die bei Programmaufruf gestartet wird.
function main()
  print("pepper pot emittance meter\nby Arno Trautmann\n")
  print("Schwelle auf "..threshold.." gesetzt.")
  print("Iterationsweite auf "..iteration_width.." gesetzt.")
  print("Ausmaße der Felder werden berechnet. Es wird ein quadratisches Feld angenommen!")
  estimate_maxima(inputfile1)

  print("Datensatz 1 wird verarbeitet")
  process_file(inputfile1)

  --takes an insula and calculates it’s weights

  io.output(io.open("datapoints1","w"))
  for i = 1, #x_middle do
    io.write(x_middle[i]," ",y_middle[i]," ",particles[i],"\n")
    x_middle1[i] = x_middle[i]
    y_middle1[i] = y_middle[i]
    particles1[i] = particles[i]
  end
  io.close()

  print("Datensatz 2 wird verarbeitet")
  process_file(inputfile2)

  --takes an insula and calculates it’s weights
  io.output(io.open("datapoints2","w"))
  for i = 1, #x_middle do
    io.write(x_middle[i]," ",y_middle[i]," ",particles[i],"\n")
    x_middle2[i] = x_middle[i]
    y_middle2[i] = y_middle[i]
    particles2[i] = particles[i]
  end
  io.close()

  print("Passende Spots werden gesucht und zugeordnet.")
  match_spots()
  calculate_emittance()
  --write data to a tex-file, that will plot them (partly using gnuplot)
  write_texfile("plot-spots.tex")
  os.execute("xelatex -shell-escape -jobname='ppem-software' -interaction=batchmode plot-spots.tex")
end

main()