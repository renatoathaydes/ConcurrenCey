import ceylon.collection {
	MutableList,
	LinkedList
}

import concurrencey {
	Observable,
	equivalent
}

shared abstract class ListEvent<Element>()
		of AddEvent<Element> | RemoveEvent<Element> | ReplaceEvent<Element> {}

shared class AddEvent<Element>(shared [Integer+] indexes, shared [Element+] elements)
		extends ListEvent<Element>() {}

shared class RemoveEvent<Element>(shared [Integer+] indexes, shared [Element+] elements)
		extends ListEvent<Element>() {}

shared class ReplaceEvent<Element>(shared Integer index, shared Element element)
		extends ListEvent<Element>() {}

"A [[LinkedList]] which can be observed for modifications.
 
 This collection is NOT thread-safe."
shared class ObservableLinkedList<Element>({Element*} initialElements = {})
		extends Observable<ListEvent<Element>>()
		satisfies MutableList<Element> {
	
	value list = LinkedList(initialElements);
	
	void informObservers(ListEvent<Element> event) {
		for (observer in observers.values) {
			observer(event);
		}
	}

	shared actual void add(Element val) {
		list.add(val);
		informObservers(AddEvent([list.size - 1], [val]));
	}
	
	shared actual void addAll({Element*} values) {
		if (nonempty items = values.sequence) {
			value previousSize = list.size;
			list.addAll(values);
			value indexes = (previousSize..(list.size-1)).sequence;
			informObservers(AddEvent(indexes, items));
		}
	}
	
	shared actual void clear() {
		if (!list.empty, nonempty items = list.sequence) {
			list.clear();
			value indexes = (0..(items.size-1)).sequence;
			informObservers(RemoveEvent(indexes, items));
		}
	}
	
	shared actual void insert(Integer index, Element val) {
		list.insert(index, val);
		informObservers(AddEvent([index], [val]));
	}
	
	shared actual Element? remove(Integer index) {
		value result = list.remove(index);
		if (!is Null result) {
			informObservers(RemoveEvent([index], [result]));
		}
		return result;
	}
	
	shared actual void removeElement(Element val) {
		value indexes = LinkedList<Integer>();
		variable Integer index = 0;
		for (item in list) { // do not use entries(list) as it removes nulls
			if (equivalent(val, item)) {
				indexes.add(index);
			}
			index++;
		}
		if (nonempty removedIndexes = indexes.sequence) {
			list.removeElement(val);
			value removedValues = [val].repeat(removedIndexes.size);
			assert(nonempty removedValues);
			informObservers(RemoveEvent(removedIndexes, removedValues));	
		}
	}
	
	shared actual void set(Integer index, Element val) {
		list.set(index, val);
		informObservers(ReplaceEvent(index, val));
	}
	
	lastIndex => list.lastIndex;
	
	rest => list.rest;
	
	reversed => list.reversed;
	
	segment(Integer from, Integer length) => list.segment(from, length);
	
	clone => ObservableLinkedList(list);
	
	get(Integer index) => list.get(index);
	
	span(Integer from, Integer to) => span(from, to);
	
	spanFrom(Integer from) => list.spanFrom(from);
	
	spanTo(Integer to) => list.spanTo(to);
	
	equals(Object that) => list.equals(that);
	
	hash => list.hash;
	
}
