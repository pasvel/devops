#!/usr/sbin/python

import random
import sys
directions=['UP','DOWN','RIGHT','LEFT']

def moveY(k1,k2):
  if k2 < 0:
    z=-1
    ar='^'
  else:
    z=1
    ar='|'
  for k in range(k1+z,k1+k2,z):
    if k >= HO or k == 0:
      print "DEBUG: k=%d, HO=%d, k1=%d, k2=%d" % (k,HO,k1,k2)
      moveY(1,k-k1)
      break
    coo[k][ve]=ar
  coo[k1+k2][ve]='X'
  #print 'ho: %s->%s, ve: %s, shift: %s' % (k1,k1+k2,ve,k2)
  return k1+k2 

def moveX(k1,k2):
  if k2 < 0:
    z=-1
    ar='<'
  else:
    z=1
    ar='>'
  for k in range(k1+z,k1+k2,z):
    coo[ho][k]=ar
  coo[ho][k1+k2]='X'
  #print 'ho: %s, ve: %s->%s, shift: %s' % (ho,k1,k1+k2,k2)
  return k1+k2

M=10
L=[];
VE=M*20+1-11
HO=M*4+1+7
ho=HO//2
ve=VE//2
coo=[['.' for x in range(1,VE)] for x in range(1,HO)]

coo[ho][ve]='X'
for i in coo: print ''.join(i)

while True:
  L=[]
  s=raw_input().split(' ')
  if not s: break
  L.append(s)
#for k in range(1,M+1):
#  L.append((random.choice(directions), random.randrange(1,M)))

  for l in L:
    #print 'FULL: %s, 1: %s, 2: %s' % (l,l[0],l[1])
    coo[ho][ve]='O'
    if l[0]=='': break
    elif l[0]=='UP' or l[0]=='DOWN':
      if l[0]=='DOWN': x=int(l[1])
      else: x=-int(l[1])
      print 'HO=%d, VE=%d, DIRECTION: %s, VALUE=%s' % (ho,ve,l[0],x)
      ho=moveY(ho,x)

    elif l[0]=='LEFT' or l[0]=='RIGHT':
      if l[0]=='LEFT': x=-int(l[1])
      else: x=int(l[1])
      print 'HO=%d, VE=%d, DIRECTION: %s, VALUE=%s' % (ho,ve,l[0],x)
      ve=moveX(ve,x)

  #elif l[0]=='RIGHT': ho+=int(l[1])
  #elif l[0]=='LEFT': ho-=int(l[1])

  for i in coo: print ''.join(i)
  #raw_input()

'''
ve=0; ho=0
for x in text.split('\n'):
  l=x.split(' ')
  if l[0]=='': break
  elif l[0]=='UP': ve+=int(l[1])
  elif l[0]=='DOWN': ve-=int(l[1])
  elif l[0]=='RIGHT': ho+=int(l[1])
  elif l[0]=='LEFT': ho-=int(l[1])
print 'Coordinates: (%d,%d)' % (ho,ve)
di=((ho**2 + ve**2)**0.5)
print di
'''
