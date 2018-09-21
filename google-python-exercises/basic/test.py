
words = ['bbb', 'ccc', 'axx', 'xzz', 'xaa', 'huy', 'fuc', 'gim', 'xuy', 'xyz', 'bla']

i=0
zwords = []; rem = []
print words
words.sort()
print words
for w in words:
  print 'DEBUG w='+w
  if w.startswith('x'):
    print 'DEBUG +' + w
    zwords.append(w)
    print 'UPD zwords='; print zwords
    rem.append(i)
    #words.remove(w)
    print 'REM words='; print words
  else: print 'DEBUG -' + w
  i+=1
  print 'DEBUG i=' + str(i)
print 'rem='
print rem
rem.reverse()
print rem
for i in rem: del words[i]
print zwords + words
