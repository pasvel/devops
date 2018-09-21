#!/usr/bin/python
# Copyright 2010 Google Inc.
# Licensed under the Apache License, Version 2.0
# http://www.apache.org/licenses/LICENSE-2.0

# Google's Python Class
# http://code.google.com/edu/languages/google-python-class/

import sys
import os
import re
import operator

"""Baby Names exercise

Define the extract_names() function below and change main()
to call it.

For writing regex, it's nice to include a copy of the target
text for inspiration.

Here's what the html looks like in the baby.html files:
...
<h3 align="center">Popularity in 1990</h3>
....
<tr align="right"><td>1</td><td>Michael</td><td>Jessica</td>
<tr align="right"><td>2</td><td>Christopher</td><td>Ashley</td>
<tr align="right"><td>3</td><td>Matthew</td><td>Brittany</td>
...

Suggested milestones for incremental development:
 -Extract the year and print it
 -Extract the names and rank numbers and just print them
 -Get the names data into a dict and print it
 -Build the [year, 'name rank', ... ] list and print it
 -Fix main() to use the extract_names list
"""

def extract_names(filename):
  """
  Given a file name for baby.html, returns a list starting with the year string
  followed by the name-rank strings in alphabetical order.
  ['2006', 'Aaliyah 91', Aaron 57', 'Abagail 895', ' ...]
  """
  big=open('summary.txt', 'a') 
  fbaby=open(filename, 'rU')
  year=re.search(r'[12]\d\d\d', fbaby.name).group()
  data=re.findall(r'>(\d+)<.+?>([A-Z]\w+)<.+?>([A-Z]\w+)<', fbaby.read())
  #data=[year + ', ' + '%s, %s, %s' % t for t in re.findall(r'>(\d+)<.+?>([A-Z]\w+)<.+?>([A-Z]\w+)<', fbaby.read())]
  #for t in sorted(data, key=fnsort1): print t
  #print sorted(data, key=fnsort1)
  #data=[year + ', ' + '%s, %s, %s' % t for t in sorted(data, key=lambda x: x[2])]
  #data=[year + ', ' + '%s, %s, %s' % d for d in sorted(data, key=operator.itemgetter(1))]
  #for d in sorted(data, key=operator.itemgetter(1)):
  print 'Writing data to file for ' + year + '...'
  #for d in data: big.write(year + ' ' + '%s %s %s ' % d)
  for d in data: big.write(year + ' ' + '%s %s %s\n' % d)

  #data=[year + c for c in data]
  #for row in data: row.append(year)
  #print data
  #t=[ '%s, %s, %s' % t for t in data]
  # +++your code here+++
  fbaby.close()
  big.close()
  return

#def mysort(v):
#  return v[0][1]

"""def make_dict(s, i):
  if s[i] in md:
    print 'gotcha'
    md[s[i]].append((s[0], s[1]))
  else:
    md[s[i]] = [(s[0], s[1])]
    
    for x in md.keys():
      print x + ' : ' + str(md[x])

  return md[s[i]].append((s[0], s[1]))"""

def count_rating(f):
  mn={};
  with open('summary.txt', 'rU') as F:
    for f in F:
      i=2 # define index. 2- men, 3 - women
      s=(f.strip().split())
      #for i in (2,3):
      if s[i] not in mn: mn[s[i]]=[]
      mn[s[i]].append((s[0], s[1]))

    for d in mn.keys():
      rat=0
      for k, t in enumerate(mn[d], 1):
        rat=rat+int(t[1])
        #print d + ' : ' + str(t) + ' :' + str(k)
      mn[d].insert(0, (k, rat))
      """
      if s[2] in mn:
        mn[s[2]].append((s[0], s[1]))
        #for d in mn[s[2]]:
        #  print d
      else:
        mn[s[2]] = [(s[0], s[1])]"""

      #for w in f.strip().split():
      #  print w

  #for k, v in mn.items():
  #  print k + ': ' + str(v)
  #for k, v in sorted(sorted(mn.items(), key=lambda x: (x[1][0][1])), key=lambda x: (x[1][0][0]), reverse=True)[:40]:
  for k, v in sorted(mn.items(), key=lambda x: (-x[1][0][0], x[1][0][1]))[:40]:
    print '%-20s\tGlobal rating: %s\t: Years in TOP:\t%s\tYear/Pos in rating: ' % (k, v[0][1], v[0][0]),# + '\tYear, rating: ' + str(v[2:])
    #print '%s\tGlobal rating: %s\t: Years in TOP:\t%sYear/Place: ' % (k, str(v[0][1], str(v[0][0])# + '\tYear, rating: ' + str(v[2:])
    #print k + '\t\tGlobal rating: ' + str(v[0][1]) + '\t: Years in TOP: ' + str(v[0][0]) + '\tYear/Place: ',# + '\tYear, rating: ' + str(v[2:])
    for x in v[1:]: print '%s-%s' % x,
      #print x[0] + '-' + x[1],
    print
  #for x in mn.keys():
  #  print x + ' : ' + str(mn[x])

  """
  me=[]; men=[]
  big=open('summary.txt', 'rU')
  for l in big:
    t=tuple(l.split())

    if t[2] in me:
      i=me.index(t[2])
      me[i+1] = int(me[i+1]) + 1
      me[i+2] = int(me[i+2]) + int(t[1])
    else:
      me.append(t[2])
      me.append(1)
      me.append(t[1])

  for i in range(0,len(me), 3):
    t=(me[i], me[i+1], me[i+2])
    men.append(t)

  for i in sorted(men, key=mysort, reverse=False)[:20]:
    print '%s, years in ratings: %s, rating for years: %s' % i

  """
  #print sorted(tmp, key=mysort)
    #me.append(me)

  #for k in sorted(me.items(), key=mysort, reverse=True): print k
  #print me.items()
    #t=('%s %s %s %s' % l)
    #print t
    #print t
    #t=tuple(line.splitlines())
    #print t[2]
    #print t[3]
    #if t[2] in m: m[
  #lst=['%s, %s, %s, %s' % t for t in big.read().split('\n')]
  #for t in big.read().split('\n'):
  #lst=big.read().split()
  #for k in range(len(lst)):
  #print lst[:5]
  #for t in big.read().split('\n'):

  return


def main():
  # This command-line parsing code is provided.
  # Make a list of command line arguments, omitting the [0] element
  # which is the script itself.
  #args = sys.argv[1:]

  #if not args:
  #  print 'usage: [--summaryfile] file [file ...]'
  #  sys.exit(1)

  # Notice the summary flag and remove it from args if it is present.
  #summary = False
  #if args[0] == '--summaryfile':
  #  summary = True
  #  del args[0]

  os.remove('summary.txt') 
  #for f in os.listdir('/root/google-python-exercises/babynames'):
  for f in os.listdir('/usr/local/git/devops/google-python-exercises/babynames'):
    if '.html' in f: extract_names(f)

  count_rating('summary.txt')
    #extract_names(f)

  # +++your code here+++
  # For each filename, get the names, then either print the text output
  # or write it to a summary file
  
if __name__ == '__main__':
  main()
