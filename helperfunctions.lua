-- just a very stupid way to write the numbers with only 2 digits.
function ii(number)
  return math.floor(number*100)/100
end
-- dito, for 5
function v(number)
  return math.floor(number*100000)/100000
end

function color(number)
  r = "red" b = "blue" y = "yellow" o = "orange" g = "green" c = "cyan" p = "purple" bl = "black"
  magnitude = -math.floor(math.log10(number))
  number = number*10^(magnitude+1)
  if magnitude>6 then fc = bl sc = bl
    elseif magnitude == 6 then fc = bl sc = b
    elseif magnitude == 5 then fc = b sc = c
    elseif magnitude == 4 then fc = c sc = g
    elseif magnitude == 3 then fc = g sc = r
    elseif magnitude == 2 then fc = r sc = y
    elseif magnitude == 1 then fc = y sc = y
  end
  return "\\color{"..fc.."!"..(number).."!"..sc.."}"
end

--For short questions to the user: anything including "y" or "j" will be accepted (y,j,yes,ja, …)
function yes(input)
  return (string.find(input, "y") or  string.find(input, "j"))
end