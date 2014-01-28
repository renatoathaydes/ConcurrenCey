#ConcurrenCey

ConcurrenCey is a Ceylon library that makes it trivial to write concurrent, multi-threaded code.

It is currently under active development. Please contact me if you would like to contribute!

Here's a quick example of what code written with CeylonFX looks like *(this example already works)*:

```ceylon
value firstLane = Lane("First lane");
value secondLane = Lane("Second lane");

Integer fact(Integer i) {
	assert(i > 0);
	if (i == 1) { return 1; }
	else { return i * fact(i - 1); }
}

value factOf10 = Action(() => fact(10)).runOn(firstLane);
value factOf12 = Action(() => fact(12)).runOn(secondLane);

print("10! = ``factOf10.get()``, 12! = ``factOf12.get()``");
```

## Getting started

You just need to add this declaration to your Ceylon module:

```ceylon
import concurrencey "0.0.1"
```

