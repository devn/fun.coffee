inc = (x) -> x + 1

dec = (x) -> x - 1

sum = (a, b) -> a + b

even = (x) -> x % 2 is 0

odd = (x) -> x % 2 is 1

identity = (x) -> x

toFn = (obj) -> (p) -> obj[p]

get = (coll, x) -> if coll then coll[x] else null

getIn = (x, keys) -> reduce get, x, keys

accsr = (x, coll) -> coll[x]

flip = (f) -> (a, b) -> f b, a

apply = (f, args) -> f.apply null, args

call = (f, args...) -> f.apply null, args

partial = (f, rest1...) -> (rest2...) -> f.apply null, rest1.concat rest2

arity = (arities) ->
  (args...) ->
    arities[args.length or 'default'].apply null, args

dispatch = (dfn, table) ->
  f = (args...) -> table[dfn.apply(null, args) or 'default'].apply null, args
  f._table = table
  f

extendfn = (gfn, exts) ->
  for t, f of exts
    gfn._table[t] = f

# ==============================================================================
# Strict Sequences

groupBy = (pred, coll) ->
  r = {}
  for x in coll
    v = pred x
    r[v] ||= []
    r[v].push x
  r

strictMap = (f, colls...) ->
  if colls.length is 1
    f x for x, i in colls[0]
  else
    first = colls[0]
    for _, i in first
      f.apply null, x[i] for x in colls

strictReduce = arity
  2: (f, coll) -> strictReduce f, coll[0], coll[1..]
  3: (f, acc, coll) ->
    for x in coll
      acc = f(acc, x)
    acc

strictFilter = (pred, coll) ->
  x for x in coll when pred(x)

strictPartition = arity
  1: (n, coll) -> strictPartition coll, n, false
  2: (n, pad, coll) ->
    r = []
    last = null
    while coll.length > 0
      last = coll[0..n]
      r.push last
      if pad and last.length < n
        last[n] = null
      coll = coll[n..]
    r

# ==============================================================================
# Lazy Sequences

class LazySeq
  constructor: (@head, @tail) ->
  first: -> @head
  rest: -> if @tail then @tail() else null

lazyseq = (h, t) -> new LazySeq h, t

toLazy = (coll) ->
  if coll.length is 0
    return null
  h = coll[0]
  lazyseq h, -> lazy coll[1..]

toArray = (s) ->
  acc = []
  while s
    acc.push s.first()
    s = s.rest()
  acc

integers = arity
  0: -> integers 0
  1: (x) -> lazyseq x, -> integers x+1

fib = ->
  fibSeq = (a, b) -> lazyseq a, -> fibSeq b, a+b
  fibSeq 0, 1

range = arity
  1: (end) -> range 0, end
  2: (start, end) ->
    if start is end
      null
    else
      lazyseq start, -> range inc(start), end

repeat = arity
  1: (x) -> lazyseq n, -> repeat n
  2: (n, x) -> take n, repeat x

repeatedly = arity
  1: (f) -> lazyseq f(), -> repeatedly f
  2: (n, f) -> take n, repeatedly f

cycle = (coll) ->
  cyclefn = (i) ->
    i = i % coll.length
    lazyseq coll[i], -> cyclefn i+1
  cyclefn(0)

lazyConcat = (a, b) ->
  if a is null
    b
  else
    lazyseq a.first(), -> lazyConcat a.rest(), b

lazyPartition = arity
  2: (n, coll) ->
  3: (n, coll, pad) ->
    p = take n, coll
    r = drop n, coll
    if r is null
      null
    else
      lazyseq p, -> r

drop = arity
  1: (coll) -> drop 1, coll
  2: (n, coll) ->
    if coll is null
      null
    else if n is 0
      coll
    else
      drop n-1, rest coll

take = (n, s) ->
  if n is 0 or s is null
    null
  else
    lazyseq s.first(), -> take dec(n), s.rest()

last = (s) ->
  c = null
  while s
    c = s.first()
    s = s.rest()
  c

lazyMap = (f, s) ->
  if s
    lazyseq f(s.first()), -> lazyMap f, s.rest()
  else
    null

lazyReduce = arity
  2: (f, s) -> lazyReduce f, s.first(), s.rest()
  3: (f, acc, s) ->
    while s
      acc = f acc, s.first()
      s = s.rest()
    acc

lazyFilter = (pred, s) ->
  if s
    h = s.first()
    if pred h
      lazyseq h, -> lazyFilter pred, s.rest()
    else
      lazyFilter pred, s.rest()
  else
    null

# ==============================================================================
# Generic

seqType = arity
  2: (f, s) ->
    s.constructor.name
  default: (f, _, s) ->
    seqType f, s

map = dispatch seqType,
  Array: strictMap
  LazySeq: lazyMap

filter = dispatch seqType,
  Array: strictFilter
  LazySeq: lazyFilter

reduce = dispatch seqType,
  Array: strictReduce
  LazySeq: lazyReduce

concat = dispatch seqType,
  Array: Array.prototype.concat
  LazySeq: lazyConcat

partition = dispatch seqType,
  Array: strictPartition
  LazySeq: lazyPartition

# ==============================================================================
# Exports

toExport =
  inc: inc
  dec: dec
  sum: sum
  even: even
  odd: odd
  identity: identity
  toFn: toFn
  get: get
  getIn: getIn
  flip: flip
  apply: apply
  call: call
  partial: partial
  arity: arity
  dispatch: dispatch
  extendfn: extendfn
  strictMap: strictMap
  strictRduce: strictReduce
  strictFilter: strictFilter
  groupBy: groupBy
  partition: partition
  LazySeq: LazySeq
  lazyseq: lazyseq
  toLazy: toLazy
  toArray: toArray
  repeat: repeat
  repeatedly: repeatedly
  cycle: cycle
  drop: drop
  take: take
  lazyMap: lazyMap
  lazyReduce: lazyReduce
  lazyFilter: lazyFilter
  integers: integers
  range: range
  fib: fib
  last: last
  seqType: seqType
  map: map
  filter: filter
  reduce: reduce
  concat: concat

if exports?
  for n, f of toExport
    exports[n] = f

if window?
  window.Fun = {}
  for n, f of toExport
    window.Fun[n] = f
