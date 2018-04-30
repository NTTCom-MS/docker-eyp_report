import sys, json, string
data = json.load(sys.stdin)["operatingsystem_support"]

#<ac:emoticon ac:name="tick"/> <ac:emoticon ac:name="cross"/>

os = {}

for item in range(len(data)):
	for ver in range(len(data[item]["operatingsystemrelease"])):
		os[data[item]["operatingsystem"]+' '+data[item]["operatingsystemrelease"][ver]]='<ac:emoticon ac:name="tick"/>'

#print os

display = [ 'CentOS 6', 'CentOS 7', 'RedHat 6', 'RedHat 7', 'Ubuntu 14.04', 'Ubuntu 16.04', 'Ubuntu 18.04', 'SLES 11.3' ]
for item in display:
	if not item in os:
		os[item]='<ac:emoticon ac:name="cross"/>'

sys.stdout.write('<td>'+os["CentOS 6"]+'</td>')
sys.stdout.write('<td>'+os["CentOS 7"]+'</td>')
sys.stdout.write('<td>'+os["RedHat 6"]+'</td>')
sys.stdout.write('<td>'+os["RedHat 6"]+'</td>')
sys.stdout.write('<td>'+os["Ubuntu 14.04"]+'</td>')
sys.stdout.write('<td>'+os["Ubuntu 16.04"]+'</td>')
sys.stdout.write('<td>'+os["Ubuntu 18.04"]+'</td>')
sys.stdout.write('<td>'+os["SLES 11.3"]+'</td>')
#sys.stdout.write('</table></tbody>')
sys.stdout.flush()
