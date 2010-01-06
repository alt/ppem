function write_texfile(texfile)
  header = "\\documentclass{scrartcl}\\usepackage{booktabs,gnuplottex,supertabular,tabularx,xcolor,xltxtra}\\setlength{\\parindent}{0em}\\pagestyle{empty}\\begin{document}"
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
  io.write("\\minisec{\\LARGE Auswertung des pepper-pot emittance meter} \\vspace*{2em}\\begin{itemize}\\item Schwelle = ",threshold,", Iterationsweite = ",iteration_width,"\\item Abstand passender Punkte = ",distance,", Verschiebung [mm] = ",displacement,"\\item Relative Höhe benachbarter Punkte: ",relative_hight,"\\end{itemize}")
  io.write("\\minisec{2D-Plot der erkannten Spots}")
  io.write(plotarguments,inputfile1,"';")
  io.write('p "datapoints1"',egnu,"\n")
  io.write(plotarguments,inputfile2,"';")
  io.write('p "datapoints2"',egnu,"\n\n")
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
--
  io.write(#spots_not_matched.." Spots im Datensatz 1 konnten nicht zugeordnet werden: \\\\")
  for i = 1,#spots_not_matched do
    io.write(spots_not_matched[i].."\n\n")
  end

  io.write("\\newpage")
  io.write("\\begin{gnuplot}unset key;set title 'x -- dx';set style data dots; p 'phase_space_diagramm_x'\\end{gnuplot}\n\n")
  io.write("\\begin{gnuplot}unset key;set title 'y -- dy';set style data dots; p 'phase_space_diagramm_y'\\end{gnuplot}\n\n")
  io.write("\\newpage\\minisec{Phasenraumdiagramm x}")
  io.write("\\small\\hspace*{-.15\\textwidth}\\fbox{\\scalebox{"..530/xmax.."}{\\begin{picture}("..xmax..","..(xmax/2)..")")

graph_factorx1 = xmax/10 --stretch
graph_factorx2 = 0.5    --shift
  for i = 1,#spot_x do
    io.write("\\put("..spot_x[i]..","..(graph_factorx1*spot_dx[i]+xmax*graph_factorx2).."){"..color(particles[i]).."\\textbullet}\n")
  end
  io.write(epic)
graph_factory1 = ymax/10 --stretch
graph_factory2 = 0.1    --shift
  io.write("\\minisec{Phasenraumdiagramm y}")
--[[  io.write("\\small\\hspace*{-.15\\textwidth}\\fbox{\\scalebox{"..530/ymax.."}{\\begin{picture}("..ymax..","..(ymax/2)..")")
  for i = 1,#spot_y do
    io.write("\\put("..spot_y[i]..","..(graph_factory1*spot_dy[i]+ymax*graph_factory2).."){"..color(particles[i]).."\\textbullet}\n")
  end
  io.write(epic.."\\\\")--]]
  io.write(edoc)
  io.close()
end