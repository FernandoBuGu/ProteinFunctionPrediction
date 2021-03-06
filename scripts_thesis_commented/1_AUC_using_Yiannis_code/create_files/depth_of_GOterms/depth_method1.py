import urllib2

#Script to compute depth of a GO term using .py code. This method gives very smilar results than method2. Deliverable is a file with a dataframe with two columns. The first column is the GO term id and the second column is the depth.


    #MSc thesis bioinfomratics WUR. Protein function prediction for poorly annotated species.
    #Author: Fernando Bueno Gutierrez
    #email1: fernando.buenogutierrez@wur.nl
    #email2: fernando.bueno.gutie@gmail.com




def return_level(code):
	go_id=str(code)
	response = urllib2.urlopen("http://supfam.cs.bris.ac.uk/SUPERFAMILY/cgi-bin/go.cgi?search=GO%3A"+go_id.split(":")[1])

	for line in response.readlines():
		if line.startswith("<tr><td align=right><font color=#FF0000>"):
		    value = int(line.split(":")[0].split()[-1])
		    break
	level = value + 1
	return level



filename = open("/home/bueno002/gos/GOES", "r")
m_file = filename.readlines()





for line in m_file:
	print line
	try:
		level=return_level(line.rstrip())	#if error, go to next
		levels = open("/home/bueno002/gos/levels", "a")
		levels.write(str(line.rstrip()))
		levels.write("\t")
		levels.write(str(level))
		levels.write("\n")
	except:
		pass
	levels.close()







