import ceylon.test {
	test,
	assertEquals
}

import concurrencey {
	equivalent
}


class ObservableLinkedListTest() {
	
	value list = ObservableLinkedList<String>();
	
	shared test void observerNotifiedOnAdd() {
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);
		
		list.add("Hi");
		
		assert(is AddEvent<String> final = result);
		assertEquals(final.indexes, [0]);
		assertEquals(final.elements, ["Hi"]);
		assertEquals(list, ["Hi"]);
	}
	
	shared test void observerNotifiedOnAddAll() {
		list.add("Hi");
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);
		
		list.addAll({"B", "C"});
		
		assert(is AddEvent<String> final = result);
		assertEquals(final.indexes, [1, 2]);
		assertEquals(final.elements, ["B", "C"]);
		assertEquals(list, ["Hi", "B", "C"]);
	}
	
	shared test void observerNotifiedOnClear() {
		list.addAll({"A", "B", "C"});
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);
		
		list.clear();
		
		assert(is RemoveEvent<String> final = result);
		assertEquals(final.indexes, [0, 1, 2]);
		assertEquals(final.elements, ["A", "B", "C"]);
		assertEquals(list, []);
	}
	
	shared test void observerNotifiedOnInsert() {
		list.addAll({"A", "B", "C"});
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);
		
		list.insert(2, "M");
		
		assert(is AddEvent<String> final = result);
		assertEquals(final.indexes, [2]);
		assertEquals(final.elements, ["M"]);
		assertEquals(list, ["A", "B", "M", "C"]);
	}
	
	shared test void observerNotifiedOnRemove() {
		list.addAll({"A", "B", "C", "D"});
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);
		
		value returned = list.remove(2);
		
		assert(is RemoveEvent<String> final = result);
		assertEquals(final.indexes, [2]);
		assertEquals(final.elements, ["C"]);
		assertEquals(returned, "C");
		assertEquals(list, ["A", "B", "D"]);
	}
	
	shared test void observerNotifiedOnRemoveElement() {
		value list = ObservableLinkedList<String?>({"A", "B", "A", "A", null, "C"});
		variable ListEvent<String?>|Exception result = Exception();
		list.observe((ListEvent<String?>|Exception e) => result = e);
		
		list.removeElement("A");
		
		assert(is RemoveEvent<String?> final = result);
		assertEquals(final.indexes, [0, 2, 3]);
		assertEquals(final.elements, ["A", "A", "A"]);
		assertEquals(list, ["B", null, "C"], null, equivalent);
		
		list.removeElement(null);
		
		assert(is RemoveEvent<String?> final2 = result);
		assertEquals(final2.indexes, [1]);
		assertEquals(final2.elements, [null]);
		assertEquals(list, ["B", "C"]);
	}
	
	shared test void observerNotifiedOnSet() {
		list.addAll({"A", "B"});
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);
		
		list.set(1, "C");
		
		assert(is ReplaceEvent<String> final = result);
		assertEquals(final.index, 1);
		assertEquals(final.element, "C");
		assertEquals(list, ["A", "C"]);
	}
	
	shared test void notNotifiedWhenRemoveElementDoesNotModifyList() {
		value list = ObservableLinkedList<String?>();
		list.addAll({"A", null, "B"});
		variable Integer count = 0;
		list.observe((ListEvent<String?>|Exception e) => count++);
		
		list.removeElement("C");
		
		assertEquals(count, 0);
	}

}