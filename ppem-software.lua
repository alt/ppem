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

*todo*
--]]


--global variables 199/304
--”user interface“
inputfile1 = "daten/09-09-01-1b.cod"
inputfile2 = "daten/09-09-01-2b.cod"
threshold = 8e-6 --minimum number of particles in one pixel to be not neglected
iteration_width = 4 --maximum number of steps between one point of an insula and the next one
distance = 8        --maximum distance of two matching spots
displacement = 0    --displacement of the detector in mm.

--FIXME! x and y are puzzled!
--[[ WARNING: if you change the cut_edges, you have to change the threshold, too, to get usefull results!--]]
cut_edges = 7

--global variables, only initialization.
xmax,ymax = 0,0

insulae = {}

insula_index = 1
insula_subindex = 1

x_middle = {}   --array for spots (x)
y_middle = {}   --array for spots (y)
particles = {}  --array for spots (№ of particles in that spot)
n = 0           --total № of particles

x_middle1 = {} y_middle1 = {} particles1 = {}
x_middle2 = {} y_middle2 = {} particles2 = {}

--estimates the xmax_est and ymax_est to automatically be used instead of manually setting xmax, ymax.
function estimate_maxima(file)
  io.input(io.open(file))
  x_one = io.read("*number")
  tmp = io.read()
  x_two = io.read("*number")
  io.input(close)
  steps = 2*x_one / (x_one-x_two) + 1
--steps=801
  xmax,ymax = steps,steps
  print("Schritte: "..steps)

  y_min = cut_edges --actually x
  y_max = ymax - cut_edges
  x_min = cut_edges --actually y
  x_max = xmax - cut_edges
  print("Grenzen angepasst.")
end

-- prepares a temporary file with the cut edges. The first run will take much time, but the next run will be much shorter because the field does not need to be prepared again.
function cut_borders(file)
print("Hilfsdatei für diese Ränder wird erstellt.\n Dies kann einige Zeit in Anspruch nehmen!")
  io.input(file)

  tmpline = {}
  for x = 1,xmax do
  tmpline[x] = {}
    for y = 1,ymax do
      tmpline[x][y] = io.read()
    end
  end
  io.input(close)
print("Originaldaten gelesen und in tmpline gespeichert.")
  io.output(io.open(file.."_cut_"..cut_edges,"w"))
  for x = 1,xmax do
    for y = 1,ymax do
        if ((x > x_min) and (x < x_max) and (y > y_min) and (y < y_max)) then
          io.write(string.sub(tmpline[x][y],-14,-1).."\n")
        else
        end
      end
    end
  io.close()
end

--reads the field from the helper file (with the "_cut_") in it
function read2dfrom1d(file)
  totalnumberinplot = 0
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
      totalnumberinplot = totalnumberinplot + field[x][y]
    end
  end
  io.input(close)
  return field,totalnumberinplot
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

--helper function:
--tries to find all members of a single island
--if trigger is too low, will raise an error when hitting the edes!
function scan_island(x,y)
  if insulafield[x][y] > 0 then

    insulae[insula_index][insula_subindex] = {}
    insulae[insula_index][insula_subindex][1] = x
    insulae[insula_index][insula_subindex][2] = y
    insulae[insula_index][insula_subindex][3] = insulafield[x][y]

    insulafield[x][y] = 0                --got it, set it to 0 so it won’t be scanned again
    insula_subindex = insula_subindex +1 --next item gets to the next entry of this insula

    for i = 1,iteration_width do
      for j = 1,iteration_width do
        scan_island(x-i,y)
        scan_island(x-i,y+j)
        scan_island(x-i,y-j)
        scan_island(x,y+j)
        scan_island(x+i,y+j)
        scan_island(x+i,y)
        scan_island(x+i,y-j)
      end
    end
  end
end

--calculates the weights of each spot
function determine_spot_positionss(savefile)
  x_tmp = 0; y_tmp = 0               --for the calculation of <x²>, <y²>
  x_tmp_square = 0; y_tmp_square = 0 --for the calculation of <x²>, <y²>

  io.output(io.open(savefile,"w"))

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

    io.write("Spot "..i.." ("..particles[i].." Teilchen): \n")
    io.write("  X-Mittelwert: ",x_middle[i],"\n")
    io.write("  Y-Mittelwert: ",y_middle[i].."\n\n")
  end
  io.close()
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
        spot_dx[k] = x_middle1[i] - x_middle2[i]
        spot_y[k] = y_middle1[i]
        spot_dy[k] = y_middle1[i] - y_middle2[i]
        particles[k] = particles1[i]

        found_matching = true
      end
    end
    if not(found_matching) then
      table.insert(spots_not_matched,i)
    end
  end
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

-- just a very stupid way to write the numbers with only 2 digits.
function ii(number)
  return math.floor(number*100)/100
end
-- dito, for 5
function v(number)
  return math.floor(number*100000)/100000
end

function write_texfile(texfile)
  header = "\\documentclass{scrartcl}\\usepackage{booktabs,gnuplottex,siunitx,supertabular,tabularx,xcolor,xltxtra}\\setlength{\\parindent}{0em}\\pagestyle{empty}\\begin{document}"
  edoc = "\\end{document}"
  bgnu = "\\begin{gnuplot}"
  egnu = "\\end{gnuplot}"
  epic = "\\end{picture}}}"
  esup = "\\bottomrule\\end{supertabular}"
  black = "\\color{black}"
  blue = "\\color{blue}"
  red = "\\color{red}"

  plotarguments = "\\hspace*{-.4\\textwidth}"..bgnu.."[scale=1.1]\n unset auto; unset key; set xrange [0 to "..xmax.."]; set yrange [0 to "..ymax.."];set style data dots;set size ratio 1; set title '"
  io.output(io.open(texfile,"w"))
  io.write(header)
  io.write("\\minisec{\\LARGE Auswertung des pepper-pot emittance meter}")
  io.write("\\minisec{2D-Plot der erkannten Spots}")
  io.write(plotarguments..inputfile1.."';")
  io.write('p "datapoints1"'..egnu.."\n")
  io.write(plotarguments..inputfile2.."';")
  io.write('p "datapoints2"'..egnu.."\n\n")
--
  io.write("\\newpage\\minisec{Zuordnung der Spots \\small"..red.." Datensatz 1 $\\Rightarrow$ "..blue.." Datensatz 2}")
  io.write("\\small\\hspace*{-.15\\textwidth}\\fbox{\\scalebox{"..530/xmax.."}{\\begin{picture}("..xmax..","..ymax..")")
  for i = 1, math.min(#x_middle1,#x_middle2) do
    io.write("\\put("..x_middle1[i]..","..y_middle1[i].."){"..red.."\\llap{"..i.."}\\textbullet}".."\n")
      io.write("\\put("..x_middle2[i]..","..y_middle2[i].."){"..blue.."\\textbullet\\rlap{"..i.."}}".."\n")
  end
  io.write(epic)
--
  lr = ">{"..red.."}r"
  lb = ">{"..blue.."}r"
  tabhead = "r"..lr..lr..lr..lb..lb..lb.."lll"
  io.write("\\newpage\\begin{supertabular}{"..tabhead.."}\n")
  hline="\\\\ \n"
--io.write("\\toprule Spot № & x1 & y1 & rel. Anzahl & x2 & y2 & rel. Anzahl"..hline.."\\midrule")
io.write("\\toprule Spot № & x & y & Anz. & x & y & Anz. & $\\Delta$ x & $\\Delta$ y & Anz."..hline.."\\midrule")
  for i = 1, math.max(#x_middle1,#x_middle2) do
    if x_middle1[i] then 
        io.write(i.."& "..ii(x_middle1[i]) .."&"..ii(y_middle1[i]).."&"..v(particles1[i]).."&")
    else
      io.write(i.."&&\\llap{nicht vorhanden}&&")
    end
    if x_middle2[i] then
      io.write(ii(x_middle2[i]).."&"..ii(y_middle2[i]).."&"..v(particles2[i]))
    else
      io.write("&&&&\\llap{nicht vorhanden}")
    end

    if (x_middle2[i] and x_middle1[i]) then  
      io.write("&"..ii(x_middle1[i]-x_middle2[i]).."&"..ii(y_middle1[i]-y_middle2[i]).."&"..v(particles1[i]-particles2[i])..hline)
    else
      io.write("& \\rlap{Differenz nicht vorhanden}"..hline)
    end
    io.write("\\midrule")
  end
  io.write(esup.."\\newpage")

  io.write(#spots_not_matched.." Spots im Datensatz 1 konnten nicht zugeordnet werden: \\\\")
  for i = 1,#spots_not_matched do
    io.write(spots_not_matched[i].."\n\n")
  end

  io.write("\\newpage\\begin{gnuplot}unset key; set title 'x--dx'; set style data dots; p 'phase_space_diagramm_x'\\end{gnuplot}\n\n")
  io.write("\\begin{gnuplot}unset key; set title 'y--dy'; set style data dots; p 'phase_space_diagramm_y'\\end{gnuplot}\n\n")
  io.write("\\begin{gnuplot}unset key; set title 'x--dx'; set style data dots; sp 'phase_space_diagramm_x'\\end{gnuplot}\n\n")
  io.write("\\begin{gnuplot}unset key; set title 'y--dy'; set style data dots; sp 'phase_space_diagramm_y'\\end{gnuplot}\n\n")
  io.write(edoc)
  io.close()
end

  --For short questions to the user: anything including "y" or "j" will be accepted (y,j,yes,ja, …)
function yes(input)
  return (string.find(input, "y") or  string.find(input, "j"))
end

function process_file(file)
  local tmpfile = io.open(file.."_cut_"..cut_edges)
  if tmpfile then
    io.close(tmpfile)
  else
  print("Hilfsdatei ("..file.."_cut_"..cut_edges..") existiert nicht!")
    cut_borders(file)
  end

  --read the datafile
  mainfield,total = read2dfrom1d(file.."_cut_"..cut_edges)

  mainfield = normalize_field(mainfield,total)

  --cut off the borders (eliminate edge-effects)
  insulafield = cut_border_and_threshold(mainfield)

  --scans for isolated areas. That will be the spots we’re looking for!
  scan_for_insulae()
end

--Die Hauptfunktion, die bei Programmaufruf gestartet wird.
function main()
  print("pepper pot emittance meter\nby Arno Trautmann\n")
  print("Schwelle auf "..threshold.." gesetzt.")
  print("Iterationsweite auf "..iteration_width.." gesetzt.")
  print("Ausmaße der Felder werden berechnet. Es wird ein quadratisches Feld angenommen!")
  estimate_maxima(inputfile1)
  print("Daten liegen in "..xmax.." Schritten vor.")

  print("Datensatz 1 wird verarbeitet")
  process_file(inputfile1)

  --takes an insula and calculates it’s weights
  determine_spot_positionss("ppem_insulae_1.txt")

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
  determine_spot_positionss("ppem_insulae_2.txt")

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

  --write data to a tex-file, that will plot them (partly using gnuplot)
  write_texfile("plot-spots.tex")
  os.execute("xelatex -shell-escape -interaction=batchmode -jobname='ppem-software' plot-spots.tex")
numbersinplot = 1
  for i = 1,#particles1 do
    numbersinplot = numbersinplot + particles1[i]
  end
print("Gesamtanzahl im Datensatz 1: "..numbersinplot)
end

main()