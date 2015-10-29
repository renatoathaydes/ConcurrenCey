import ceylon.collection {
    MutableList,
    LinkedList,
    HashSet
}

import com.athaydes.concurrencey {
    Observable
}

"Any event that may modify a list."
shared abstract class ListEvent<Element>()
		of AddEvent<Element> | RemoveEvent<Element> | ReplaceEvent<Element> {}

"Event representing the addition of new elements to a List."
shared class AddEvent<Element>(
    "Indexes of the added elements." shared [Integer+] indexes,
    "The added elements." shared [Element+] elements)
		extends ListEvent<Element>() {}

"Event representing the removal of elements from a List."
shared class RemoveEvent<Element>(
    "Indexes of the removed elements." shared [Integer+] indexes,
    "The removed elements" shared [Element+] elements)
		extends ListEvent<Element>() {}

"Event representing the replacement of one or more elements of a List."
shared class ReplaceEvent<Element>(
    "Index of the replaced element" shared Integer index,
    "The new value of the element" shared Element element)
		extends ListEvent<Element>() {}

"A [[LinkedList]] which can be observed for modifications.

 This collection is NOT thread-safe."
shared class ObservableLinkedList<Element>({Element*} initialElements = {})
		extends Observable<ListEvent<Element>>()
		satisfies MutableList<Element>
        given Element satisfies Object {

    LinkedList<Element> list = LinkedList(initialElements);

    void informObservers(ListEvent<Element> event) {
		for (Anything(ListEvent<Element>|Exception) observer in super.observers.items) {
			observer(event);
		}
	}
	
	Integer internalRemoveAll({Element*} elements) {
		HashSet<Element> toRemove = HashSet { elements = elements; };
		LinkedList<Integer> indexes = LinkedList<Integer>();
		LinkedList<Element> values = LinkedList<Element>();
		
		variable Integer index = 0;
		for (Element item in list) {
			if (item in toRemove) {
				indexes.add(index);
				values.add(item);
			}
			index++;
		}
		variable Integer removedCount = 0;
		if (nonempty removedIndexes = indexes.sequence(), nonempty removed = values.sequence()) {
			removedCount += list.removeAll(elements);
			informObservers(RemoveEvent(removedIndexes, removed));
		}
		return removedCount;
	}

	shared actual void add(Element val) {
		list.add(val);
		informObservers(AddEvent([list.size - 1], [val]));
	}

	shared actual void addAll({Element*} values) {
		if (nonempty items = values.sequence()) {
			Integer previousSize = list.size;
			list.addAll(values);
			[Integer+] indexes = (previousSize..(list.size-1)).sequence();
			informObservers(AddEvent(indexes, items));
		}
	}

	shared actual void clear() {
		if (!list.empty, nonempty items = list.sequence()) {
			list.clear();
			[Integer+] indexes = (0..(items.size-1)).sequence();
			informObservers(RemoveEvent(indexes, items));
		}
	}

	shared actual void insert(Integer index, Element val) {
		list.insert(index, val);
		informObservers(AddEvent([index], [val]));
	}

	shared actual Integer remove(Element val) {
		return internalRemoveAll({val});
	}

	shared actual void set(Integer index, Element val) {
		list.set(index, val);
		informObservers(ReplaceEvent(index, val));
	}

	lastIndex => list.lastIndex;

	rest => list.rest;

	reversed => list.reversed;

	span(Integer from, Integer to) => span(from, to);

	spanFrom(Integer from) => list.spanFrom(from);

	spanTo(Integer to) => list.spanTo(to);

	equals(Object that) => list.equals(that);

	hash => list.hash;

	shared actual Element? delete(Integer index) {
		Element? removed = list.delete(index);
		if (exists removed) {
			informObservers(RemoveEvent([index], [removed]));
		}
		return removed;
	}

	shared actual void deleteSpan(Integer from, Integer to) {
		deleteMeasure(from, to + 1 - from);
	}

	shared actual void infill(Element replacement) {
		// nulls are not allowed
	}

	shared actual void prune() {
		// nulls are not allowed
	}

	shared actual Integer removeAll({Element*} elements) {
		return internalRemoveAll(elements);
	}

	shared actual Boolean removeFirst(Element element) {
		Boolean removed = list.removeFirst(element);
		if (removed) {
			informObservers(RemoveEvent([0], [element]));
		}
		return removed;
	}

	shared actual Boolean removeLast(Element element) {
		Boolean removed = list.removeLast(element);
		if (removed) {
			informObservers(RemoveEvent([list.size], [element]));
		}
		return removed;
	}
	shared actual void replace(Element element, Element replacement) {
		LinkedList<Integer> indexes = LinkedList<Integer>();
		for (index -> item in zipEntries((0..list.size), list)) {
			if (item == element) {
				indexes.add(index);
			}
		}
		list.replace(element, replacement);
		for (Integer index in indexes) {
			informObservers(ReplaceEvent(index, replacement));
		}
	}

	shared actual Boolean replaceFirst(Element element, Element replacement) {
		Boolean replaced = list.replaceFirst(element, replacement);
		if (replaced) {
			informObservers(ReplaceEvent(0, replacement));
		}
		return replaced;
	}

	shared actual Boolean replaceLast(Element element, Element replacement) {
		Boolean replaced = list.replaceLast(element, replacement);
		if (replaced) {
			informObservers(ReplaceEvent(list.size, replacement));
		}
		return replaced;
	}

	shared actual void truncate(Integer size) {
		Integer initialSize = list.size;
		List<Element> removedElements = list[size..list.size];
		list.truncate(size);
		Integer finalSize = list.size;
		[Integer+] removedIndexes = (size..(finalSize - initialSize)).sequence();
		if (is [Element+] removedElements)  {
		  informObservers(RemoveEvent(removedIndexes, removedElements));	
		}
	}
	
	shared actual void deleteMeasure(Integer from, Integer length) {
		List<Element> elementsToRemove = list[from:length].sequence();
		if (is [Element+] elementsToRemove) {
			list.deleteMeasure(from, elementsToRemove.size);
			Range<Integer> removedIndexes = (from..(from + elementsToRemove.size - 1));
			informObservers(RemoveEvent(removedIndexes, elementsToRemove));	
		}
	}
	
	getFromFirst(Integer index) => list.getFromFirst(index);
	
	clone() => ObservableLinkedList(list);
	
	


}
